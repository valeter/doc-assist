variable "billing_account_id" {
  type = string
  sensitive   = true
}

variable "service_account_id" {
  type = string
  sensitive   = true
}

variable "organization_id" {
  type = string
  sensitive   = true
}

variable "developers" {
  type = list(string)
  sensitive   = true
}

variable "doc_assist_version" {
  type = string
  default = null
}

variable "telegram_token" {
  type        = string
  sensitive   = true
}
