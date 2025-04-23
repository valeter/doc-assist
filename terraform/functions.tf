resource "yandex_function" "doc-assist" {
  count = var.doc_assist_version == null ? 0 : 1

  folder_id          = local.functions_folder_id
  name               = "doc-assist"
  description        = "python-driven telegram bot document assistant"
  user_hash          = var.doc_assist_version
  runtime            = "python39"
  entrypoint         = "server.handleRequest"
  memory             = "128"
  execution_timeout  = "60"
  service_account_id = yandex_iam_service_account.func-sa.id
  environment = {
    FOLDER_ID = local.functions_folder_id
  }
  secrets {
    id                   = yandex_lockbox_secret.aws.id
    version_id           = data.yandex_lockbox_secret_version.aws-sa-static-key-version.id
    key                  = "key_id"
    environment_variable = "AWS_ACCESS_KEY_ID"
  }
  secrets {
    id                   = yandex_lockbox_secret.aws.id
    version_id           = data.yandex_lockbox_secret_version.aws-sa-static-key-version.id
    key                  = "key"
    environment_variable = "AWS_SECRET_ACCESS_KEY"
  }
  secrets {
    id                   = yandex_lockbox_secret.telegram.id
    version_id           = data.yandex_lockbox_secret_version.telegram-version.id
    key                  = "telegram_token"
    environment_variable = "TELEGRAM_TOKEN"
  }
  package {
    bucket_name = yandex_storage_bucket.doc-assist-functions-bucket.bucket
    object_name = var.doc_assist_version
  }
  async_invocation {
    retries_count      = "2"
    service_account_id = yandex_iam_service_account.func-sa.id
  }
  log_options {
    log_group_id = yandex_logging_group.doc-assist-log.id
  }
  concurrency = 1
  mounts {
    name = "doc-assist-docs"
    mode       = "ro"
    object_storage {
      bucket = "doc-assist-docs"
    }
  }
}