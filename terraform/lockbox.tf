// object storage
resource "yandex_lockbox_secret" "aws" {
  folder_id = local.secrets_folder_id
  name      = "aws"
}

resource "yandex_lockbox_secret_iam_binding" "aws-viewer" {
  secret_id = yandex_lockbox_secret.aws.id
  role      = "viewer"
  members = [
    "group:${yandex_organizationmanager_group.doc-assist-dev.id}",
  ]
}

data "yandex_lockbox_secret_version" "aws-sa-static-key-version" {
  secret_id  = yandex_lockbox_secret.aws.id
  version_id = yandex_iam_service_account_static_access_key.aws-sa-static-key.output_to_lockbox_version_id
  depends_on = [yandex_lockbox_secret.aws]
}

// telegram token
resource "yandex_lockbox_secret" "telegram" {
  folder_id = local.secrets_folder_id
  name      = "telegram"
}

resource "yandex_lockbox_secret_iam_binding" "telegram-viewer" {
  secret_id = yandex_lockbox_secret.telegram.id
  role      = "viewer"
  members = [
    "group:${yandex_organizationmanager_group.doc-assist-dev.id}",
  ]
}

resource "yandex_lockbox_secret_version_hashed" "telegram-version" {
  secret_id  = yandex_lockbox_secret.telegram.id
  key_1     = "telegram_token"
  text_value_1 = var.telegram_token
  depends_on = [yandex_lockbox_secret.telegram]
}

data "yandex_lockbox_secret_version" "telegram-version" {
  secret_id  = yandex_lockbox_secret.telegram.id
  version_id = yandex_lockbox_secret_version_hashed.telegram-version.id
}


// outputs
output "aws_access_key" {
  value     = data.yandex_lockbox_secret_version.aws-sa-static-key-version.entries[1].text_value
  sensitive = true
}

output "aws_secret_key" {
  value     = data.yandex_lockbox_secret_version.aws-sa-static-key-version.entries[0].text_value
  sensitive = true
}