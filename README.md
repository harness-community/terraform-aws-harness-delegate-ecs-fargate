# terraform-aws-harness-delegate-ecs-fargate

Deploy a harness delegate on ecs fargate using terraform

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Delegate name | `string` | | yes |
| harness_account_id | Harness account id | `string` | | yes |
| delegate_token_secret_arn | Secret manager secret that holds the delegate token | `string` | | yes |
| delegate_policy_arn | An IAM policy to use for the task role, gives your delegate access to AWS | `string` | | no |
| security_groups | VPC security groups to place the delegate pods in | `list(string)` | | yes |
| subnets | VPC subnets to place the delegate pods in | `list(string)` | | yes |
| manager_host_and_port | Value from delegate yaml | `string` | https://app.harness.io/gratis | no |
| watcher_storage_url | Value from delegate yaml | `string` | https://app.harness.io/public/prod/premium/watchers | no |
| delegate_storage_url | Value from delegate yaml | `string` | https://app.harness.io | no |
| watcher_check_location | Value from delegate yaml | `string` | current.version | no |
| cdn_url | Value from delegate yaml | `string` | https://app.harness.io | no |
| remote_watcher_url_cdn | Value from delegate yaml | `string` | https://app.harness.io/public/shared/watchers/builds | no |
| delegate_description | Value from delegate yaml | `string` | | no |
| delegate_tags | Value from delegate yaml | `string` | | no |
| proxy_manager | Value from delegate yaml | `string` | | no |

## Resources

| Name | Type |
|------|------|
|this|aws_cloudwatch_log_group|
|this|aws_ecs_cluster|
|task_execution|aws_iam_role|
|task_execution|aws_iam_policy|
|task_execution|aws_iam_role_policy_attachment|
|task|aws_iam_role|
|task|aws_iam_role_policy_attachment|
|this|aws_ecs_task_definition|
|this|aws_ecs_service|

## Outputs

| Name | Description |
|------|-------------|
| aws_ecs_task_definition | The ARN of the ECS task definition |
| aws_ecs_service | The ARN of the ECS service |
