// object storage
resource "yandex_iam_service_account" "aws-sa" {
  folder_id   = local.sa_folder_id
  name        = "aws-sa"
  description = "AWS-like service account for doc-assist bot"
}

resource "yandex_resourcemanager_folder_iam_member" "aws-sa-os-editor" {
  folder_id = local.storage_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.aws-sa.id}"
}

resource "yandex_iam_service_account_static_access_key" "aws-sa-static-key" {
  service_account_id = yandex_iam_service_account.aws-sa.id
  output_to_lockbox {
    entry_for_access_key = "key_id"
    entry_for_secret_key = "key"
    secret_id            = yandex_lockbox_secret.aws.id
  }
}

// serverless function invoker
resource "yandex_iam_service_account" "func-sa" {
  folder_id   = local.sa_folder_id
  name        = "func-sa"
  description = "serverless function invoker service account for doc-assist bot"
}

resource "yandex_resourcemanager_cloud_iam_member" "func-sa-functionInvoker" {
  cloud_id = yandex_resourcemanager_cloud.doc-assist.id
  role     = "functions.functionInvoker"
  member   = "serviceAccount:${yandex_iam_service_account.func-sa.id}"
}

resource "yandex_resourcemanager_cloud_iam_member" "func-sa-storageViewer" {
  cloud_id = yandex_resourcemanager_cloud.doc-assist.id
  role     = "storage.viewer"
  member   = "serviceAccount:${yandex_iam_service_account.func-sa.id}"
}

resource "yandex_resourcemanager_cloud_iam_member" "func-sa-aiEditor" {
  cloud_id = yandex_resourcemanager_cloud.doc-assist.id
  role     = "ai.assistants.editor"
  member   = "serviceAccount:${yandex_iam_service_account.func-sa.id}"
}

resource "yandex_resourcemanager_cloud_iam_member" "func-sa-lmUser" {
  cloud_id = yandex_resourcemanager_cloud.doc-assist.id
  role     = "ai.languageModels.user"
  member   = "serviceAccount:${yandex_iam_service_account.func-sa.id}"
}

resource "yandex_resourcemanager_cloud_iam_member" "func-sa-lockbox-payloadViewer" {
  cloud_id = yandex_resourcemanager_cloud.doc-assist.id
  role     = "lockbox.payloadViewer"
  member   = "serviceAccount:${yandex_iam_service_account.func-sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "func-sa-logging-writer" {
  folder_id = local.logging_folder_id
  role      = "logging.writer"
  member    = "serviceAccount:${yandex_iam_service_account.func-sa.id}"
}