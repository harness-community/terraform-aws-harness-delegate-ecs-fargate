variable "harness_account_id" {
  type        = string
  description = "Harness account id"
}

variable "delegate_token_secret_arn" {
  type        = string
  description = "Secret manager secret that holds the delegate token"
}

variable "delegate_policy_arn" {
  type        = string
  description = "IAM policy to use for the task role, gives your delegate access to AWS"
}

variable "security_groups" {
  type        = list(string)
  description = "VPC security groups to place the delegate pods in"
}

variable "subnets" {
  type        = list(string)
  description = "VPC subnets to place the delegate pods in"
}

# delegate configuration

variable "manager_host_and_port" {
  type    = string
  default = "https://app.harness.io/gratis"
}

variable "watcher_storage_url" {
  type    = string
  default = "https://app.harness.io/public/prod/premium/watchers"
}
variable "delegate_storage_url" {
  type    = string
  default = "https://app.harness.io"
}

variable "watcher_check_location" {
  type    = string
  default = "current.version"
}

variable "cdn_url" {
  type    = string
  default = "https://app.harness.io"
}

variable "remote_watcher_url_cdn" {
  type    = string
  default = "https://app.harness.io/public/shared/watchers/builds"
}

variable "delegate_description" {
  type    = string
  default = ""
}

variable "delegate_tags" {
  type    = string
  default = ""
}

variable "proxy_manager" {
  type    = string
  default = ""
}
