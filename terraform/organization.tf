// doc_assist_dev
resource "yandex_organizationmanager_group" "doc-assist-dev" {
  name            = "doc-assist-dev"
  description     = "doc-assist bot developers"
  organization_id = var.organization_id
}

resource "yandex_organizationmanager_group_membership" "doc-assist-dev-membership" {
  group_id = yandex_organizationmanager_group.doc-assist-dev.id
  members  = var.developers
}

resource "yandex_organizationmanager_organization_iam_member" "doc-assist-dev-auditor" {
  organization_id = var.organization_id
  role            = "auditor"
  member          = "group:${yandex_organizationmanager_group.doc-assist-dev.id}"
}

resource "yandex_organizationmanager_organization_iam_member" "doc-assist-dev-logging-reader" {
  organization_id = var.organization_id
  role            = "logging.reader"
  member          = "group:${yandex_organizationmanager_group.doc-assist-dev.id}"
}

resource "yandex_organizationmanager_organization_iam_member" "doc-assist-dev-monitoring-viewer" {
  organization_id = var.organization_id
  role            = "monitoring.viewer"
  member          = "group:${yandex_organizationmanager_group.doc-assist-dev.id}"
}

resource "yandex_organizationmanager_organization_iam_member" "doc-assist-dev-viewer" {
  organization_id = var.organization_id
  role            = "viewer"
  member          = "group:${yandex_organizationmanager_group.doc-assist-dev.id}"
}

resource "yandex_organizationmanager_organization_iam_member" "doc-assist-dev-monitoring-editor" {
  organization_id = var.organization_id
  role            = "monitoring.editor"
  member          = "group:${yandex_organizationmanager_group.doc-assist-dev.id}"
}

resource "yandex_organizationmanager_os_login_settings" "os_login_settings" {
  organization_id = var.organization_id
  ssh_certificate_settings {
    enabled = true
  }
  user_ssh_key_settings {
    enabled               = true
    allow_manage_own_keys = true
  }
}