data "harness_platform_current_account" "current" {}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  harness_account_id = var.harness_account_id != null ? var.harness_account_id : data.harness_platform_current_account.current.id
}