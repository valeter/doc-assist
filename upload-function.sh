#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Ошибка: Необходимо указать версию функции"
    exit 1
fi

source upload-function-vars.sh

# Создаем временную директорию
mkdir -p temp_deploy
cp doc-assist-bot/server.py temp_deploy/
cp doc-assist-bot/requirements.txt temp_deploy/

# Создаем архив из временной директории
cd temp_deploy
zip -r ../doc-assist-$1.zip .
cd ..

# Очищаем временную директорию
rm -rf temp_deploy

aws --endpoint-url=https://storage.yandexcloud.net/ s3 cp ./doc-assist-$1.zip s3://doc-assist-functions