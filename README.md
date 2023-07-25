# terraform-aws-harness-delegate-ecs-fargate

Deploy a harness delegate on ecs fargate using terraform.

Optionally, create an ECS [drone runner](https://docs.drone.io/runner/vm/drivers/amazon/) to enable VM builds in [Harness CIE](https://harness.io/technical-blog/harness-ci-aws-vms).

## Delegate Example

Your delegate token should be stored in AWS Secrets Manager as a plaintext secret.
![image](https://github.com/harness-community/terraform-aws-harness-delegate-ecs-fargate/assets/7338312/94b60805-88ec-4ccd-8b9c-59b3688e33fa)

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
  source                    = "git::https://github.com/harness-community/terraform-aws-harness-delegate-ecs-fargate.git"
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

## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

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
| [aws_efs_access_point.runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_access_point) | resource |
| [aws_efs_file_system.runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_file_system) | resource |
| [aws_efs_mount_target.runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/efs_mount_target) | resource |
| [aws_iam_policy.task_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy.task_execution_registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_exec](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.task_execution_registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_base64_runner_config"></a> [base64\_runner\_config](#input\_base64\_runner\_config) | An AWS drone runner config base64 encoded | `string` | `""` | no |
| <a name="input_cdn_url"></a> [cdn\_url](#input\_cdn\_url) | n/a | `string` | `"https://app.harness.io"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | ID for the ECS cluster to use | `string` | `""` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name for the ECS cluster created by the module | `string` | `"harness-delegate"` | no |
| <a name="input_delegate_check_location"></a> [delegate\_check\_location](#input\_delegate\_check\_location) | n/a | `string` | `"delegateprod.txt"` | no |
| <a name="input_delegate_description"></a> [delegate\_description](#input\_delegate\_description) | n/a | `string` | `""` | no |
| <a name="input_delegate_image"></a> [delegate\_image](#input\_delegate\_image) | n/a | `string` | `"harness/delegate:latest"` | no |
| <a name="input_delegate_policy_arns"></a> [delegate\_policy\_arns](#input\_delegate\_policy\_arns) | IAM policies to use for the task role, gives your delegate access to AWS | `list(string)` | n/a | yes |
| <a name="input_delegate_storage_url"></a> [delegate\_storage\_url](#input\_delegate\_storage\_url) | n/a | `string` | `"https://app.harness.io"` | no |
| <a name="input_delegate_tags"></a> [delegate\_tags](#input\_delegate\_tags) | n/a | `string` | `""` | no |
| <a name="input_delegate_token_secret_arn"></a> [delegate\_token\_secret\_arn](#input\_delegate\_token\_secret\_arn) | Secret manager secret that holds the delegate token | `string` | n/a | yes |
| <a name="input_enable_ecs_exec"></a> [enable\_ecs\_exec](#input\_enable\_ecs\_exec) | Create policy to enable ecs execution on delegate container | `bool` | `false` | no |
| <a name="input_harness_account_id"></a> [harness\_account\_id](#input\_harness\_account\_id) | Harness account id | `string` | n/a | yes |
| <a name="input_init_script"></a> [init\_script](#input\_init\_script) | n/a | `string` | `""` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | A KMS key to use for encrypting the EFS volume | `string` | `""` | no |
| <a name="input_log_streaming_service_url"></a> [log\_streaming\_service\_url](#input\_log\_streaming\_service\_url) | n/a | `string` | `"https://app.harness.io/gratis/log-service/"` | no |
| <a name="input_manager_host_and_port"></a> [manager\_host\_and\_port](#input\_manager\_host\_and\_port) | n/a | `string` | `"https://app.harness.io/gratis"` | no |
| <a name="input_name"></a> [name](#input\_name) | Delegate name | `string` | n/a | yes |
| <a name="input_proxy_manager"></a> [proxy\_manager](#input\_proxy\_manager) | n/a | `string` | `""` | no |
| <a name="input_delegate_environment"></a> [delegate\_environment](#input\_delegate\_environment) | Additional environment variables to add to the delegate | `list(object({ name = string, value = string }))` | `[]` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | number of delegate tasks | `number` | `1` | no |
| <a name="input_registry_secret_arn"></a> [registry\_secret\_arn](#input\_registry\_secret\_arn) | Secret manager secret that holds the login for a container registry | `string` | `""` | no |
| <a name="input_remote_watcher_url_cdn"></a> [remote\_watcher\_url\_cdn](#input\_remote\_watcher\_url\_cdn) | n/a | `string` | `"https://app.harness.io/public/shared/watchers/builds"` | no |
| <a name="input_runner_config"></a> [runner\_config](#input\_runner\_config) | An AWS drone runner config | `string` | `""` | no |
| <a name="input_runner_image"></a> [runner\_image](#input\_runner\_image) | n/a | `string` | `"drone/drone-runner-aws"` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | VPC security groups to place the delegate pods in | `list(string)` | n/a | yes |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | VPC subnets to place the delegate pods in | `list(string)` | n/a | yes |
| <a name="input_watcher_check_location"></a> [watcher\_check\_location](#input\_watcher\_check\_location) | n/a | `string` | `"current.version"` | no |
| <a name="input_watcher_storage_url"></a> [watcher\_storage\_url](#input\_watcher\_storage\_url) | n/a | `string` | `"https://app.harness.io/public/prod/premium/watchers"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_aws_ecs_cluster"></a> [aws\_ecs\_cluster](#output\_aws\_ecs\_cluster) | The ID of the ECS cluster |
| <a name="output_aws_ecs_service"></a> [aws\_ecs\_service](#output\_aws\_ecs\_service) | The ID of the ECS service |
| <a name="output_aws_ecs_task_definition"></a> [aws\_ecs\_task\_definition](#output\_aws\_ecs\_task\_definition) | The ARN of the ECS task definition |
| <a name="output_aws_efs_file_system"></a> [aws\_efs\_file\_system](#output\_aws\_efs\_file\_system) | The filesystem used for drone runner |
| <a name="output_aws_iam_role_task"></a> [aws\_iam\_role\_task](#output\_aws\_iam\_role\_task) | The IAM role for the ECS task |
| <a name="output_aws_iam_role_task_execution"></a> [aws\_iam\_role\_task\_execution](#output\_aws\_iam\_role\_task\_execution) | The IAM role for ECS execution |
