import json
import os
import boto3
import chardet
import pathlib
from telegram import Update, Message
from telegram.ext import Application, CommandHandler, ContextTypes, MessageHandler, filters
from yandex_cloud_ml_sdk import YCloudML
from yandex_cloud_ml_sdk.search_indexes import (
    StaticIndexChunkingStrategy,
    TextSearchIndexType,
)

# Получаем токен бота из переменных окружения
TELEGRAM_TOKEN = os.environ.get('TELEGRAM_TOKEN')
AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')

iam_token = ""

# Инициализация клиента Yandex Object Storage
s3_client = boto3.client(
    's3',
    endpoint_url='https://storage.yandexcloud.net',
    aws_access_key_id=AWS_ACCESS_KEY_ID,
    aws_secret_access_key=AWS_SECRET_ACCESS_KEY
)

def check_s3_directory_exists(bucket_name: str, directory_name: str) -> bool:
    """Проверяет существование директории в Yandex Object Storage"""
    try:
        response = s3_client.list_objects_v2(
            Bucket=bucket_name,
            Prefix=f"{directory_name}/",
            MaxKeys=1
        )
        return 'Contents' in response
    except Exception as e:
        print(f"Ошибка при проверке директории в Object Storage: {str(e)}")
        return False

def create_s3_directory(bucket_name: str, directory_name: str) -> None:
    """Создает директорию в Yandex Object Storage"""
    try:
        # В Object Storage директории создаются путем добавления '/' в конце ключа
        s3_client.put_object(Bucket=bucket_name, Key=f"{directory_name}/")
    except Exception as e:
        print(f"Ошибка при создании директории в Object Storage: {str(e)}")
        raise

async def ping(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик команды /ping"""
    print("ping command received")
    await update.message.reply_text('pong')

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик команды /start"""
    print("start command received")
    try:
        # Определяем ID чата (группы или пользователя)
        chat_id = str(update.effective_chat.id)
        
        # Создаем директорию в S3
        create_s3_directory("doc-assist-docs", chat_id)
        
        # Отправляем приветственное сообщение
        await update.message.reply_text(
            "Привет! Теперь загружайте в меня документы с помощью команды /upload "
            "и после этого можете задавать по ним любые вопросы командой /ask"
        )
    except Exception as e:
        await update.message.reply_text(
            "Произошла ошибка при инициализации. Пожалуйста, попробуйте позже."
        )
        print(f"Ошибка в команде /start: {str(e)}")

def save_user_state(chat_id: str, message_id: int) -> None:
    """Сохраняет состояние пользователя в S3"""
    try:
        s3_client.put_object(
            Bucket="doc-assist-docs",
            Key=f"{chat_id}/state.json",
            Body=json.dumps({"file_request_message_id": message_id}),
            ContentType='application/json'
        )
    except Exception as e:
        print(f"Ошибка при сохранении состояния: {str(e)}")
        raise

def get_user_state(chat_id: str) -> dict:
    """Получает состояние пользователя из S3"""
    try:
        response = s3_client.get_object(
            Bucket="doc-assist-docs",
            Key=f"{chat_id}/state.json"
        )
        return json.loads(response['Body'].read().decode('utf-8'))
    except Exception as e:
        print(f"Ошибка при получении состояния: {str(e)}")
        return {}

def clear_user_state(chat_id: str) -> None:
    """Очищает состояние пользователя в S3"""
    try:
        s3_client.delete_object(
            Bucket="doc-assist-docs",
            Key=f"{chat_id}/state.json"
        )
    except Exception as e:
        print(f"Ошибка при очистке состояния: {str(e)}")

async def upload(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик команды /upload"""
    print("upload command received")
    chat_id = str(update.effective_chat.id)
    
    # Проверяем, инициализирован ли чат
    if not check_s3_directory_exists("doc-assist-docs", chat_id):
        await update.message.reply_text("Пожалуйста, инициализируйте меня командой /start")
        return
    
    # Сохраняем ID сообщения с запросом файла
    request_message = await update.message.reply_text(
        "Пожалуйста, отправьте мне текстовый файл в ответ на это сообщение"
    )
    save_user_state(chat_id, request_message.message_id)

async def handle_document(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик загруженных файлов"""
    print("document received")
    chat_id = str(update.effective_chat.id)
    
    # Проверяем, инициализирован ли чат
    if not check_s3_directory_exists("doc-assist-docs", chat_id):
        await update.message.reply_text("Пожалуйста, инициализируйте меня командой /start")
        return
    
    # Получаем состояние пользователя
    user_state = get_user_state(chat_id)
    expected_message_id = user_state.get('file_request_message_id')
    
    # Проверяем, что файл отправлен в ответ на сообщение с запросом
    if not update.message.reply_to_message or \
       update.message.reply_to_message.message_id != expected_message_id:
        print(f"file not sent in response to the request message, ignoring {update.message.reply_to_message.message_id if update.message.reply_to_message else 'None'} {expected_message_id}")
        return
    
    document = update.message.document
    
    # Проверяем размер файла (1MB = 1024 * 1024 bytes)
    if document.file_size > 1024 * 1024:
        await update.message.reply_text("Ваш файл больше 1МБ, пожалуйста, загрузите файл меньшего размера")
        return
    
    # Пытаемся определить кодировку и прочитать файл
    try:
        # Скачиваем файл в память
        file = await context.bot.get_file(document.file_id)
        file_data = await file.download_as_bytearray()
        
        result = chardet.detect(file_data)
        encoding = result['encoding']
        
        if not encoding:
            raise ValueError("Не удалось определить кодировку файла")
        
        # Пробуем прочитать файл в определенной кодировке
        try:
            text = file_data.decode(encoding)
        except UnicodeDecodeError:
            raise ValueError(f"Файл не может быть прочитан в кодировке {encoding}")
        
        # Сохраняем файл в UTF-8
        file_name = document.file_name
        s3_key = f"{chat_id}/{file_name}"
        
        s3_client.put_object(
            Bucket="doc-assist-docs",
            Key=s3_key,
            Body=text.encode('utf-8'),
            ContentType='text/plain; charset=utf-8'
        )
        
        await update.message.reply_text("Файл успешно загружен и сохранен!")
        
    except ValueError as e:
        print(e)
        await update.message.reply_text("Кажется, Ваш файл не содержит текста, попробуйте другой файл")
    except Exception as e:
        print(e)
        await update.message.reply_text(f"Произошла ошибка при обработке файла: {str(e)}")
    finally:
        # Очищаем состояние
        clear_user_state(chat_id)


def check_user_has_files(chat_id: str) -> bool:
    """Проверяет, есть ли у пользователя загруженные файлы"""
    try:
        user_dir = os.path.join("/function/storage/doc-assist-docs", chat_id)
        return os.path.exists(user_dir) and any(
            not f.endswith('/') for f in os.listdir(user_dir)
        )
    except Exception as e:
        print(f"Ошибка при проверке файлов пользователя: {str(e)}")
        return False

async def ask(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Обработчик команды /ask"""
    print("ask command received")
    chat_id = str(update.effective_chat.id)
    
    # Проверяем наличие запроса
    if not context.args:
        await update.message.reply_text("Пожалуйста, задайте какой-нибудь вопрос: /ask <вопрос>")
        return
    
    # Проверяем инициализацию чата
    if not check_s3_directory_exists("doc-assist-docs", chat_id):
        await update.message.reply_text("Пожалуйста, инициализируйте меня командой /start")
        return
    
    # Проверяем наличие загруженных файлов
    if not check_user_has_files(chat_id):
        await update.message.reply_text("Пожалуйста, загрузите хотя бы один файл командой /upload")
        return
    
    try:
        # Инициализируем YCloudML
        sdk = YCloudML(
            folder_id=os.environ.get('FOLDER_ID'),
            auth=iam_token
        )

        user_dir = os.path.join("/function/storage/doc-assist-docs", chat_id)
        paths = pathlib.Path(user_dir).iterdir()
        
        # Создаем поисковой индекс
        files = []
        for path in paths:
            file = sdk.files.upload(
                path,
                ttl_days=1,
                expiration_policy="static",
            )
            files.append(file)

        # Создадим индекс для полнотекстового поиска по загруженным файлам.
        operation = sdk.search_indexes.create_deferred(
            files,
            index_type=TextSearchIndexType(
                chunking_strategy=StaticIndexChunkingStrategy(
                    max_chunk_size_tokens=500,
                    chunk_overlap_tokens=200,
                )
            ),
        )

        # Дождемся создания поискового индекса.
        search_index = operation.wait()

        # Создадим инструмент для работы с поисковым индексом.
        # Или даже с несколькими индексами, если бы их было больше.
        tool = sdk.tools.search_index(search_index)

        # Создадим ассистента для модели YandexGPT Pro Latest.
        # Он будет использовать инструмент поискового индекса.
        assistant = sdk.assistants.create("yandexgpt", tools=[tool])
        thread = sdk.threads.create()
        
        # Отправляем запрос ассистенту
        query = ' '.join(context.args)
        thread.write(query)
        run = assistant.run(thread)
        result = run.wait()

        # Отправляем ответ пользователю
        await update.message.reply_text(result.text)

        search_index.delete()
        thread.delete()
        assistant.delete()
    except Exception as e:
        print(f"Ошибка при обработке запроса: {str(e)}")
        await update.message.reply_text(
            "Произошла ошибка при обработке вашего запроса. Пожалуйста, попробуйте позже."
        )


async def handleRequest(event, context):
    """Точка входа для Yandex Cloud Functions"""
    try:
        global iam_token
        iam_token = context.token['access_token']
        
        # Создаем приложение бота
        application = Application.builder().token(TELEGRAM_TOKEN).build()
        
        # Добавляем обработчики команд
        application.add_handler(CommandHandler("ping", ping))
        application.add_handler(CommandHandler("start", start))
        application.add_handler(CommandHandler("upload", upload))
        application.add_handler(CommandHandler("ask", ask))
        application.add_handler(MessageHandler(filters.Document.ALL, handle_document))
        
        # Инициализируем бота
        await application.initialize()
        
        # Получаем обновление из события
        update = Update.de_json(json.loads(event['body']), application.bot)
        
        # Обрабатываем обновление
        await application.process_update(update)
        
        return {
            'statusCode': 200,
            'body': json.dumps({'ok': True})
        }
        
    except Exception as e:
        print(f"Ошибка: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
