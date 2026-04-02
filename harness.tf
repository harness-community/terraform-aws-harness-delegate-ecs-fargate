locals {
  create_delegate_token = (var.delegate_token == null) && (var.delegate_token_secret_arn == null)
  store_delegate_token  = local.create_delegate_token && (var.delegate_token_secret_key != null)
}

resource "harness_platform_delegatetoken" "this" {
  count      = local.create_delegate_token ? 1 : 0
  name       = "ecs-${var.name}-${formatdate("YYYY-MM-DD", timestamp())}"
  account_id = local.harness_account_id

  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_secretsmanager_secret" "delegate_token" {
  count       = local.store_delegate_token ? 1 : 0
  name        = var.delegate_token_secret_key
  description = "Delegate token for ECS Fargate delegate"
}

resource "aws_secretsmanager_secret_version" "delegate_token" {
  count         = local.store_delegate_token ? 1 : 0
  secret_id     = aws_secretsmanager_secret.delegate_token[0].id
  secret_string = harness_platform_delegatetoken.this[0].value
}

locals {
  delegate_token            = var.delegate_token != null ? var.delegate_token : (local.create_delegate_token ? harness_platform_delegatetoken.this[0].value : null)
  delegate_token_secret_arn = var.delegate_token_secret_arn != null ? var.delegate_token_secret_arn : (local.store_delegate_token ? aws_secretsmanager_secret.delegate_token[0].arn : null)
}
