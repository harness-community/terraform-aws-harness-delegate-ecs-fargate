variable "name" {
  type        = string
  description = "Delegate name"
}

variable "harness_account_id" {
  type        = string
  description = "Harness account id"
}

variable "delegate_token_secret_arn" {
  type        = string
  description = "Secret manager secret that holds the delegate token"
}

variable "registry_secret_arn" {
  type        = string
  description = "Secret manager secret that holds the login for a container registry"
  default     = ""
}

variable "delegate_policy_arns" {
  type        = list(string)
  description = "IAM policies to use for the task role, gives your delegate access to AWS"
}

variable "cluster_name" {
  type        = string
  default     = "harness-delegate"
  description = "Name for the ECS cluster created by the module"
}

variable "cluster_id" {
  type        = string
  default     = ""
  description = "ID for the ECS cluster to use"
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

variable "delegate_image" {
  type    = string
  default = "harness/delegate:latest"
}

variable "init_script" {
  type    = string
  default = ""
}

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

# runner configuration

variable "runner_image" {
  type    = string
  default = "drone/drone-runner-aws"
}

variable "runner_config" {
  type        = string
  description = "An AWS drone runner config"
  default     = ""
}

variable "base64_runner_config" {
  type        = string
  description = "An AWS drone runner config base64 encoded"
  default     = ""
}

variable "kms_key_id" {
  type        = string
  description = "A KMS key to use for encrypting the EFS volume"
  default     = ""
}