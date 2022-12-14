# terraform-aws-harness-delegate-ecs-fargate

Deploy a harness delegate on ecs fargate using terraform.

Optionally, create an ECS [drone runner](https://docs.drone.io/runner/vm/drivers/amazon/) to enable VM builds in [Harness CIE](https://harness.io/technical-blog/harness-ci-aws-vms).

## Delegate Example

```terraform
module "delegate" {
  source                    = "git::https://github.com/rssnyder/terraform-aws-harness-delegate-ecs-fargate.git"
  name                      = "ecs"
  harness_account_id        = "wlgELJ0TTre5aZhzpt8gVA"
  delegate_token_secret_arn = "arn:aws:secretsmanager:us-west-2:012345678901:secret:harness/delegate-zBsttc"
  delegate_policy_arns      = [
    aws_iam_policy.delegate_aws_access.arn
  ]
  security_groups = [
    module.vpc.default_security_group_id
  ]
  subnets = module.vpc.private_subnets
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.0"

  name = "this"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "type"                         = "public"
  }

  private_subnet_tags = {
    "type"                            = "private"
  }
}

resource "aws_iam_policy" "delegate_aws_access" {
  name        = "delegate_aws_access"
  description = "Policy for harness delegate aws access"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
           "Sid": "GetArtifacts",
           "Effect": "Allow",
           "Action": [
               "s3:*"
           ],
           "Resource": [
              "${aws_s3_bucket.this.arn}",
              "${aws_s3_bucket.this.arn}/*"
           ]
       }
   ]
}
EOF
}
```

## Delegate + Drone Runner Example

![terraform-aws-harness-delegate-ecs-fargate (2)](https://user-images.githubusercontent.com/7338312/207667130-ebf933d8-e1d3-462d-b0ee-9ca3e28a08dc.png)

To deploy a drone runner and enable VM based CI builds you just need your runner config file.

```
  runner_config      = file("${path.module}/pool.yml")
```

Or as a base64 encoded string

```shell
cat pool.yml | base64 -w 0
```

```
  base64_runner_config      = "dmVyc2lvbjogI...ZDdiYTI4Cg=="
```

Refer to the [drone documentation](https://docs.drone.io/runner/vm/drivers/amazon/) on all the prerequisites needed to build the yaml and set up your VPC.

```terraform
module "delegate" {
  source                    = "git::https://github.com/rssnyder/terraform-aws-harness-delegate-ecs-fargate.git"
  name                      = "ecs"
  harness_account_id        = "wlgELJ0TTre5aZhzpt8gVA"
  delegate_token_secret_arn = "arn:aws:secretsmanager:us-west-2:012345678901:secret:harness/delegate-zBsttc"
  runner_config             = file("${path.module}/pool.yml")
  delegate_policy_arns      = [
    aws_iam_policy.delegate_aws_access.arn,
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  ]
  security_groups = [
    module.vpc.default_security_group_id
  ]
  subnets = module.vpc.private_subnets
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Delegate name | `string` | | yes |
| harness_account_id | Harness account id | `string` | | yes |
| delegate_token_secret_arn | Secret manager secret that holds the delegate token | `string` | | yes |
| registry_secret_arn | Secret manager secret that holds the login for a container registry | `string` | | no |
| delegate_policy_arns | An IAM policies to use for the task role, gives your delegate access to AWS | `list(string)` | | no |
| cluster_name | Name for the ECS cluster created by the module | `string` | harness-delegate | no |
| cluster_id | ID for the ECS cluster to use | `string` | | no |
| security_groups | VPC security groups to place the delegate pods in | `list(string)` | | yes |
| subnets | VPC subnets to place the delegate pods in | `list(string)` | | yes |
| delegate_image | Delegate image to use | `string` | harness/delegate:latest | no |
| init_script | Script to run on delegate creation | `string` | | no |
| manager_host_and_port | Value from delegate yaml | `string` | https://app.harness.io/gratis | no |
| watcher_storage_url | Value from delegate yaml | `string` | https://app.harness.io/public/prod/premium/watchers | no |
| delegate_storage_url | Value from delegate yaml | `string` | https://app.harness.io | no |
| watcher_check_location | Value from delegate yaml | `string` | current.version | no |
| cdn_url | Value from delegate yaml | `string` | https://app.harness.io | no |
| remote_watcher_url_cdn | Value from delegate yaml | `string` | https://app.harness.io/public/shared/watchers/builds | no |
| delegate_description | Value from delegate yaml | `string` | | no |
| delegate_tags | Value from delegate yaml | `string` | | no |
| proxy_manager | Value from delegate yaml | `string` | | no |
| runner_image | Runner image to use | `string` | drone/drone-runner-aws | no |
| runner_config | An [AWS drone runner](https://docs.drone.io/runner/vm/drivers/amazon/) config | `string` | | no |
| base64_runner_config | An [AWS drone runner](https://docs.drone.io/runner/vm/drivers/amazon/) config base64 encoded | `string` | | no |
| kms_key_id | A KMS key to use for encrypting the EFS volume | `string` | | no |

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
|delegate|aws_ecs_task_definition|
|delegate-runner|aws_ecs_task_definition|
|this|aws_ecs_service|
|runner|aws_efs_file_system|
|runner|aws_efs_access_point|
|runner|aws_efs_mount_target|

## Outputs

| Name | Description |
|------|-------------|
| aws_ecs_cluster | The ID of the ECS cluster created |
| aws_ecs_task_definition | The ARN of the ECS task definition |
| aws_ecs_service | The ID of the ECS service |
| aws_iam_role_task_execution | The IAM role for ECS execution |
| aws_iam_role_task | The IAM role for the ECS task |
| aws_efs_file_system | The filesystem used for drone runner |
