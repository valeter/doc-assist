// prod
resource "yandex_resourcemanager_cloud" "doc-assist" {
  organization_id = var.organization_id
  name            = "doc-assist"
}

resource "yandex_billing_cloud_binding" "doc-assist-prod-billing" {
  billing_account_id = var.billing_account_id
  cloud_id           = yandex_resourcemanager_cloud.doc-assist.id
}

resource "yandex_resourcemanager_folder" "network" {
  cloud_id   = yandex_resourcemanager_cloud.doc-assist.id
  name       = "network"
  depends_on = [yandex_billing_cloud_binding.doc-assist-prod-billing]
}

resource "yandex_resourcemanager_folder" "logs" {
  cloud_id   = yandex_resourcemanager_cloud.doc-assist.id
  name       = "logs"
  depends_on = [yandex_billing_cloud_binding.doc-assist-prod-billing]
}

resource "yandex_resourcemanager_folder" "sa" {
  cloud_id   = yandex_resourcemanager_cloud.doc-assist.id
  name       = "sa"
  depends_on = [yandex_billing_cloud_binding.doc-assist-prod-billing]
}

resource "yandex_resourcemanager_folder" "secrets" {
  cloud_id   = yandex_resourcemanager_cloud.doc-assist.id
  name       = "secrets"
  depends_on = [yandex_billing_cloud_binding.doc-assist-prod-billing]
}

resource "yandex_resourcemanager_folder" "storage" {
  cloud_id   = yandex_resourcemanager_cloud.doc-assist.id
  name       = "storage"
  depends_on = [yandex_billing_cloud_binding.doc-assist-prod-billing]
}

resource "yandex_resourcemanager_folder" "functions" {
  cloud_id   = yandex_resourcemanager_cloud.doc-assist.id
  name       = "functions"
  depends_on = [yandex_billing_cloud_binding.doc-assist-prod-billing]
}