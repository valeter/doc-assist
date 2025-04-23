resource "yandex_logging_group" "doc-assist-log" {
  name      = "doc-assist-log"
  folder_id = local.logging_folder_id
}

resource "yandex_logging_group" "static-gateway-log" {
  name      = "static-gateway-log"
  folder_id = local.logging_folder_id
}