variable "name" {
  type        = string
  description = "Delegate name"
}

# Harness configuration
variable "harness_account_id" {
  type        = string
  description = "Harness account id; If not set will use from provider"
  default     = null
}

variable "delegate_token" {
  type        = string
  sensitive   = true
  description = "Delegate token to use for authentication; If this or delegate_token_secret_arn is not set, a token will be generated"
  default     = null
}

variable "delegate_token_secret_arn" {
  type        = string
  description = "Secret manager secret that holds the delegate token; If this or delegate_token is not set, a token will be generated"
  default     = null
}

variable "delegate_token_secret_key" {
  type        = string
  description = "If set, will store the created delegate token in this secret manager secret; Only used if delegate_token and delegate_token_secret_arn are not set"
  default     = null
}

# delegate image configuration
variable "delegate_image" {
  type        = string
  description = "delegate image to use, eg: harness/delegate:23.07.79906"
}

variable "registry_secret_arn" {
  type        = string
  description = "Secret manager secret that holds the login for a container registry"
  default     = ""
}

# delegate configuration
variable "delegate_check_location" {
  type    = string
  default = "delegateprod.txt"
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

variable "log_streaming_service_url" {
  type    = string
  default = "https://app.harness.io/gratis/log-service/"
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

variable "delegate_environment" {
  type        = list(object({ name = string, value = string }))
  description = "Additional environment variables to add to the delegate"
  default     = []
}

variable "desired_count" {
  type    = number
  default = 1
}

# delegate access configuration
variable "delegate_policy_arns" {
  type        = list(string)
  description = "IAM policies to use for the task role, gives your delegate access to AWS"
}

variable "enable_ecs_exec" {
  type        = bool
  description = "Create policy to enable ecs execution on delegate container"
  default     = false
}

# ecs configuration
variable "cluster_name" {
  type        = string
  default     = "harness-delegate"
  description = "Name for the ECS cluster created by the module; Used if cluster_id is not provided"
}

variable "cluster_id" {
  type        = string
  default     = null
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

variable "cpu" {
  type        = number
  description = "Number of cpu units used by the task"
  default     = 1024
}

variable "memory" {
  type        = number
  description = "Amount (in MiB) of memory used by the task"
  default     = 2048
}

# runner configuration
variable "runner_image" {
  type    = string
  default = "harness/harness-vm-runner:1.9.0"
}

variable "runner_config" {
  type        = string
  description = "A Harness VM runner pool config (YAML string)"
  default     = null
}

variable "runner_environment" {
  type        = list(object({ name = string, value = string }))
  description = "Additional environment variables to add to the runner"
  default     = []
}

variable "runner_debug" {
  type        = string
  description = "Enable debug mode for the runner"
  default     = "false"
}

variable "runner_trace" {
  type        = string
  description = "Enable trace mode for the runner"
  default     = "true"
}

variable "runner_parallel_workers" {
  type        = string
  description = "Number of parallel workers"
  default     = "1000"
}

variable "runner_poll_interval" {
  type        = string
  description = "Poll interval in milliseconds"
  default     = "1000"
}

variable "runner_skip_prepare_server" {
  type        = string
  description = "Skip prepare server step"
  default     = "true"
}

variable "runner_database_datasource" {
  type        = string
  description = "Database datasource for the runner; Only used if postgres_host is not set (used for sqlite db path)"
  default     = "database.sqlite3"
}

variable "postgres_host" {
  type        = string
  description = "PostgreSQL host for the VM runner; Set to enable PostgreSQL storage"
  default     = null
}

variable "postgres_port" {
  type        = string
  description = "PostgreSQL port"
  default     = "5432"
}

variable "postgres_ssl_mode" {
  type        = string
  description = "PostgreSQL SSL mode"
  default     = "disable"
}

variable "postgres_database" {
  type        = string
  description = "PostgreSQL database name"
  default     = "harness_runner"
}

variable "postgres_user" {
  type        = string
  description = "PostgreSQL username"
  default     = "postgres"
}

variable "postgres_password" {
  type        = string
  description = "PostgreSQL password; Required if postgres_password_secret_arn is not set"
  default     = null
}

variable "postgres_password_secret_arn" {
  type        = string
  description = "Secret manager ARN for PostgreSQL password; Required if postgres_password is not set"
  default     = null
}

variable "runner_ha_enabled" {
  type        = string
  description = "Enable HA mode for the runner"
  default     = "false"
}

variable "runner_distributed_mode" {
  type        = string
  description = "Enable distributed mode for the runner"
  default     = "false"
}

# tags
variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default     = {}
}