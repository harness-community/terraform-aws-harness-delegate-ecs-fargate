# terraform-aws-harness-delegate-ecs-fargate

Deploy a Harness delegate on ECS Fargate using Terraform.

Optionally, create an ECS [Harness VM runner](https://developer.harness.io/docs/continuous-integration/use-ci/set-up-build-infrastructure/vm-build-infrastructure/set-up-an-aws-vm-build-infrastructure) to enable VM based pipelines.

## Delegate Example

Your delegate token should be stored in AWS Secrets Manager as a plaintext secret.
![image](https://github.com/harness-community/terraform-aws-harness-delegate-ecs-fargate/assets/7338312/94b60805-88ec-4ccd-8b9c-59b3688e33fa)

You can otherwise pass a raw token, or have the module create one for you, which can be stored in AWS Secrets Manager automatically.

You should also grab the latest delegate image for your account by going to the delegate creation screen and copying the image given in the guide.
![image](https://github.com/harness-community/terraform-aws-harness-delegate-ecs-fargate/assets/7338312/59f53eb6-0af3-4dd7-970e-4e8a11417a13)

```terraform
module "delegate" {
  source                    = "git::https://github.com/harness-community/terraform-aws-harness-delegate-ecs-fargate.git"
  name                      = "ecs"
  harness_account_id        = "wlgELJ0TTre5aZhzpt8gVA"
  delegate_image            = "harness/delegate:23.07.79904"
  delegate_token_secret_arn = "arn:aws:secretsmanager:us-west-2:012345678901:secret:harness/delegate-zBsttc"
  delegate_policy_arns      = [
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  ]
  security_groups = [
    "sg-0a38670715029163f"
  ]
  subnets = [
    "subnet-0ee34605c385f4c65",
    "subnet-0f26e9386ae01a555"
  ]
}
```

## Example with Policy and Network

The policy and network here must be pre-existing resources.

```terraform
module "delegate" {
  source                    = "git::https://github.com/harness-community/terraform-aws-harness-delegate-ecs-fargate.git"
  name                      = "ecs"
  harness_account_id        = "wlgELJ0TTre5aZhzpt8gVA"
  delegate_image            = "harness/delegate:23.07.79904"
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

  name = "harness"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.4.0/24", "10.0.5.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "type" = "public"
  }

  private_subnet_tags = {
    "type" = "private"
  }
}
```

## Always use latest delegate example

```terraform
variable "harness_platform_api_key" {
  type      = string
  sensitive = true
}

data "harness_current_account" "current" {}

data "http" "latest_delegate_tag" {
  url = "https://app.harness.io/ng/api/delegate-setup/latest-supported-version?accountIdentifier=${data.harness_current_account.current.id}"

  request_headers = {
    x-api-key = var.harness_platform_api_key
  }
}

locals {
  latest_delegate_tag = jsondecode(data.http.latest_delegate_tag.response_body).resource.latestSupportedVersion
}

module "delegate" {
  source                    = "git::https://github.com/harness-community/terraform-aws-harness-delegate-ecs-fargate.git"
  name                      = "ecs"
  harness_account_id        = data.harness_current_account.current.id
  delegate_image            = "harness/delegate:${local.latest_delegate_tag}"
  delegate_token_secret_arn = "arn:aws:secretsmanager:us-west-2:012345678901:secret:harness/delegate-zBsttc"
  delegate_policy_arns      = [
    aws_iam_policy.delegate_aws_access.arn
  ]
  security_groups = [
    module.vpc.default_security_group_id
  ]
  subnets = module.vpc.private_subnets
}
```

## Delegate + Harness VM Runner Example

![terraform-aws-harness-delegate-ecs-fargate (2)](https://user-images.githubusercontent.com/7338312/207667130-ebf933d8-e1d3-462d-b0ee-9ca3e28a08dc.png)

To deploy a Harness VM runner and enable VM based pipelines builds you need:
1. A PostgreSQL database for the runner
2. Your runner pool config file (pool.yml)

### Setup

The Harness VM runner requires an IAM role for your build machines as well as a PostgreSQL database. For this we have another module which can help you provision all the required dependencies.

https://github.com/harness-community/terraform-aws-harness-byoc

You can store your PostgreSQL password in secrets manager, or reference it directly in your terraform configuration by passing it from one module to the other.

### Runner Configuration

The pool configuration is passed as a YAML string in the environemnt of the runner. You can view the pool configuration reference in the [Harness Developer Hub](https://developer.harness.io/docs/continuous-integration/use-ci/set-up-build-infrastructure/vm-build-infrastructure/set-up-an-aws-vm-build-infrastructure/#pool-settings-reference).

See [reference/pool.yaml](reference/pool.yaml) for an example pool configuration.

### Complete Example

The below example shows how to provision a Harness VM runner with an ECS delegate leveraging module for both the dependencies and the delegate/runner itself. It also show references a [module for creating a VPC](https://github.com/terraform-aws-modules/terraform-aws-vpc).

```terraform
module "ecs-byoc" {
  source = "git::https://github.com/harness-community/terraform-aws-harness-byoc.git"

  # Project configuration
  project_name = "vm-build-farm"
  aws_region   = data.aws_region.current.name

  # VPC configuration (from existing VPC)
  vpc_id               = module.vpc.vpc_id
  vpc_cidr_block       = module.vpc.vpc_cidr_block
  private_subnet_ids   = module.vpc.private_subnets
  private_subnet_cidrs = module.vpc.private_subnets_cidr_blocks

  # We are not using EKS
  iam_controller_role_name = null
  enable_pod_identity      = false

  # S3 configuration
  harness_ti_bucket_name = "vm-build-farm-harness-ti-bucket"

  build_vm_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]

  # Tags
  tags = {
    Environment = "production"
    Project     = "vm-build-farm"
  }
}

module "delegate-runner" {
  source = "git::https://github.com/harness-community/terraform-aws-harness-delegate-ecs-fargate.git"

  name = "ecs-delegate"

  delegate_image = var.delegate_image
  runner_image   = "harness/harness-vm-runner:1.9.0"

  cluster_name = "ecs-delegate"
  subnets      = module.vpc.private_subnets
  security_groups = [
    module.vpc.default_security_group_id
  ]

  delegate_policy_arns = module.ecs-byoc.iam_controller_policy_arns

  runner_config = <<EOF
version: "1"
instances:
- name: amazon
  type: amazon
  pool: 0
  limit: 3
  platform:
    arch: amd64
    os: linux
    os_name: amazon-linux
  spec:
    account:
      region: ${data.aws_region.current.name}
    ami: ami-0f4f85bd3b0ba1cb9 # you just need an AL2023 AMI with CURL installed
    disk:
      size: 105 # this depends on the AMI you use
    hibernate: true
    iam_profile_arn: ${module.ecs_byoc.iam_build_vm_instance_profile_arn}
    network:
      private_ip: true
      security_groups:
      - ${module.ecs_byoc.security_group_id}
      subnet_id: ${module.vpc.private_subnets[0]}
    size: t2.medium # this depends on your needs
EOF

  # PostgreSQL configuration
  postgres_host     = module.ecs_byoc.rds_instance_address
  postgres_port     = module.ecs_byoc.rds_instance_port
  postgres_database = module.ecs_byoc.rds_db_name
  postgres_user     = module.ecs_byoc.rds_db_username
  postgres_password = module.ecs_byoc.rds_db_password
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | >= 6.0 |
| harness | ~> 0.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 6.0 |
| harness | ~> 0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.delegate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_ecs_task_definition.delegate-runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.task_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task_execution_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task_execution_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_secretsmanager_secret.delegate_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.delegate_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [harness_platform_delegatetoken.this](https://registry.terraform.io/providers/harness/harness/latest/docs/resources/platform_delegatetoken) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [harness_platform_current_account.current](https://registry.terraform.io/providers/harness/harness/latest/docs/data-sources/platform_current_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cdn\_url | n/a | `string` | `"https://app.harness.io"` | no |
| cluster\_id | ID for the ECS cluster to use | `string` | `null` | no |
| cluster\_name | Name for the ECS cluster created by the module; Used if cluster\_id is not provided | `string` | `"harness-delegate"` | no |
| cpu | Number of cpu units used by the task | `number` | `1024` | no |
| delegate\_check\_location | delegate configuration | `string` | `"delegateprod.txt"` | no |
| delegate\_description | n/a | `string` | `""` | no |
| delegate\_environment | Additional environment variables to add to the delegate | `list(object({ name = string, value = string }))` | `[]` | no |
| delegate\_image | delegate image to use, eg: harness/delegate:23.07.79906 | `string` | n/a | yes |
| delegate\_policy\_arns | IAM policies to use for the task role, gives your delegate access to AWS | `list(string)` | n/a | yes |
| delegate\_storage\_url | n/a | `string` | `"https://app.harness.io"` | no |
| delegate\_tags | n/a | `string` | `""` | no |
| delegate\_token | Delegate token to use for authentication; If this or delegate\_token\_secret\_arn is not set, a token will be generated | `string` | `null` | no |
| delegate\_token\_secret\_arn | Secret manager secret that holds the delegate token; If this or delegate\_token is not set, a token will be generated | `string` | `null` | no |
| delegate\_token\_secret\_key | If set, will store the created delegate token in this secret manager secret; Only used if delegate\_token and delegate\_token\_secret\_arn are not set | `string` | `null` | no |
| desired\_count | n/a | `number` | `1` | no |
| enable\_ecs\_exec | Create policy to enable ecs execution on delegate container | `bool` | `false` | no |
| harness\_account\_id | Harness account id; If not set will use from provider | `string` | `null` | no |
| init\_script | n/a | `string` | `""` | no |
| log\_streaming\_service\_url | n/a | `string` | `"https://app.harness.io/gratis/log-service/"` | no |
| manager\_host\_and\_port | n/a | `string` | `"https://app.harness.io/gratis"` | no |
| memory | Amount (in MiB) of memory used by the task | `number` | `2048` | no |
| name | Delegate name | `string` | n/a | yes |
| postgres\_database | PostgreSQL database name | `string` | `"harness_runner"` | no |
| postgres\_host | PostgreSQL host for the VM runner | `string` | `null` | no |
| postgres\_password | PostgreSQL password; Required if postgres\_password\_secret\_arn is not set | `string` | `null` | no |
| postgres\_password\_secret\_arn | Secret manager ARN for PostgreSQL password; Required if postgres\_password is not set | `string` | `null` | no |
| postgres\_port | PostgreSQL port | `string` | `"5432"` | no |
| postgres\_ssl\_mode | PostgreSQL SSL mode | `string` | `"disable"` | no |
| postgres\_user | PostgreSQL username | `string` | `"postgres"` | no |
| proxy\_manager | n/a | `string` | `""` | no |
| registry\_secret\_arn | Secret manager secret that holds the login for a container registry | `string` | `""` | no |
| remote\_watcher\_url\_cdn | n/a | `string` | `"https://app.harness.io/public/shared/watchers/builds"` | no |
| runner\_config | A Harness VM runner pool config (YAML string) | `string` | `null` | no |
| runner\_debug | Enable debug mode for the runner | `string` | `"false"` | no |
| runner\_distributed\_mode | Enable distributed mode for the runner | `string` | `"false"` | no |
| runner\_environment | Additional environment variables to add to the runner | `list(object({ name = string, value = string }))` | `[]` | no |
| runner\_ha\_enabled | Enable HA mode for the runner | `string` | `"false"` | no |
| runner\_image | runner configuration | `string` | `"harness/harness-vm-runner:1.9.0"` | no |
| runner\_parallel\_workers | Number of parallel workers | `string` | `"1000"` | no |
| runner\_poll\_interval | Poll interval in milliseconds | `string` | `"1000"` | no |
| runner\_skip\_prepare\_server | Skip prepare server step | `string` | `"true"` | no |
| runner\_trace | Enable trace mode for the runner | `string` | `"true"` | no |
| security\_groups | VPC security groups to place the delegate pods in | `list(string)` | n/a | yes |
| subnets | VPC subnets to place the delegate pods in | `list(string)` | n/a | yes |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |
| watcher\_check\_location | n/a | `string` | `"current.version"` | no |
| watcher\_storage\_url | n/a | `string` | `"https://app.harness.io/public/prod/premium/watchers"` | no |

## Outputs

| Name | Description |
|------|-------------|
| aws\_ecs\_cluster | The ID of the ECS cluster |
| aws\_ecs\_service | The ID of the ECS service |
| aws\_ecs\_task\_definition | The ARN of the ECS task definition |
| aws\_iam\_role\_task | The IAM role for the ECS task |
| aws\_iam\_role\_task\_execution | The IAM role for ECS execution |