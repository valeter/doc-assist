resource "yandex_storage_bucket" "doc-assist-docs-bucket" {
  folder_id  = local.storage_folder_id
  bucket     = "doc-assist-docs"
  access_key = sensitive(data.yandex_lockbox_secret_version.aws-sa-static-key-version.entries[1].text_value)
  secret_key = sensitive(data.yandex_lockbox_secret_version.aws-sa-static-key-version.entries[0].text_value)
  max_size   = 107374182400
}

resource "yandex_storage_bucket" "doc-assist-functions-bucket" {
  folder_id  = local.storage_folder_id
  bucket     = "doc-assist-functions"
  access_key = sensitive(data.yandex_lockbox_secret_version.aws-sa-static-key-version.entries[1].text_value)
  secret_key = sensitive(data.yandex_lockbox_secret_version.aws-sa-static-key-version.entries[0].text_value)
  max_size   = 10737418240
}