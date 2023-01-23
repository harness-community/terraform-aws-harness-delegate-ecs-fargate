locals {
  runner_config = var.base64_runner_config != "" ? var.base64_runner_config : var.runner_config != "" ? base64encode(var.runner_config) : ""
}

data "aws_region" "current" {}

resource "aws_cloudwatch_log_group" "this" {
  name = "harness-delegate-${var.name}"

  tags = {
    "source" = "rssnyder/terraform-aws-harness-delegate-ecs-fargate"
  }
}

resource "aws_ecs_cluster" "this" {
  count = var.cluster_id != "" ? 0 : 1

  name = var.cluster_name
  configuration {
    execute_command_configuration {
      logging = "OVERRIDE"
      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = aws_cloudwatch_log_group.this.name
      }
    }
  }

  tags = {
    "source" = "rssnyder/terraform-aws-harness-delegate-ecs-fargate"
  }
}

resource "aws_iam_role" "task_execution" {
  name = "harness-delegate-${var.name}-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF

  tags = {
    "source"  = "rssnyder/terraform-aws-harness-delegate-ecs-fargate",
    "cluster" = var.cluster_id != "" ? var.cluster_id : aws_ecs_cluster.this[0].id
  }
}

resource "aws_iam_policy" "task_execution" {
  name        = aws_iam_role.task_execution.name
  description = "Policy for execution of the delegate container in ecs"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Logs",
            "Effect": "Allow",
            "Action": "logs:*",
            "Resource": "${aws_cloudwatch_log_group.this.arn}:log-stream:*"
        },
        {
            "Sid": "DelegateTokenSecret",
            "Effect": "Allow",
            "Action": "secretsmanager:GetSecretValue",
            "Resource": "${var.delegate_token_secret_arn}"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "task_execution_registry" {
  count = var.registry_secret_arn != "" ? 1 : 0

  name        = "${aws_iam_role.task_execution.name}_registry"
  description = "Policy for execution of the delegate container in ecs to log into image registry"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
           "Sid": "RegistryLogin",
           "Effect": "Allow",
           "Action": "secretsmanager:GetSecretValue",
           "Resource": "${var.registry_secret_arn}"
       }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution.arn
}

resource "aws_iam_role_policy_attachment" "task_execution_registry" {
  count = var.registry_secret_arn != "" ? 1 : 0

  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution_registry[0].arn
}

resource "aws_iam_role" "task" {
  name = "${var.name}-ecsTaskRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF

  tags = {
    "source"  = "rssnyder/terraform-aws-harness-delegate-ecs-fargate",
    "cluster" = var.cluster_id != "" ? var.cluster_id : aws_ecs_cluster.this[0].id
  }
}

resource "aws_iam_role_policy_attachment" "task" {
  for_each = toset(var.delegate_policy_arns)

  role       = aws_iam_role.task.name
  policy_arn = each.key
}

resource "aws_iam_policy" "task_exec" {
  count = var.enable_ecs_exec ? 1 : 0

  name        = "${aws_iam_role.task_execution.name}_task_exec"
  description = "Policy for execution of commands on the ecs containers"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "logs:DescribeLogGroups",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents"
        ],
        "Resource": "*"
      }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "task_exec" {
  count = var.enable_ecs_exec ? 1 : 0

  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task_exec[0].arn
}

resource "aws_ecs_task_definition" "delegate" {
  count = local.runner_config != "" ? 0 : 1

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  family                   = "harness-ng-delegate"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions = jsonencode([
    {
      name      = "ecs-delegate"
      image     = var.delegate_image
      essential = true
      memory    = 1024
      repositoryCredentials = var.registry_secret_arn != "" ? {
        credentialsParameter = var.registry_secret_arn
      } : null,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "ecs/delegate"
        }
      },
      secrets = [
        {
          name      = "DELEGATE_TOKEN",
          valueFrom = "${var.delegate_token_secret_arn}:::"
        }
      ],
      environment = [
        {
          name  = "ACCOUNT_ID",
          value = var.harness_account_id
        },
        {
          name  = "DELEGATE_CHECK_LOCATION",
          value = "delegatefree.txt"
        },
        {
          name  = "DELEGATE_STORAGE_URL",
          value = var.delegate_storage_url
        },
        {
          name  = "DELEGATE_TYPE",
          value = "DOCKER"
        },
        {
          name  = "INIT_SCRIPT",
          value = var.init_script
        },
        {
          name  = "DEPLOY_MODE",
          value = "KUBERNETES"
        },
        {
          name  = "MANAGER_HOST_AND_PORT",
          value = var.manager_host_and_port
        },
        {
          name  = "WATCHER_CHECK_LOCATION",
          value = var.watcher_check_location
        },
        {
          name  = "WATCHER_STORAGE_URL",
          value = var.watcher_storage_url
        },
        {
          name  = "CDN_URL",
          value = var.cdn_url
        },
        {
          name  = "REMOTE_WATCHER_URL_CDN",
          value = var.remote_watcher_url_cdn
        },
        {
          name  = "DELEGATE_NAME",
          value = var.name
        },
        {
          name  = "NEXT_GEN",
          value = "true"
        },
        {
          name  = "DELEGATE_DESCRIPTION",
          value = var.delegate_description
        },
        {
          name  = "DELEGATE_TAGS",
          value = var.delegate_tags
        },
        {
          name  = "PROXY_MANAGER",
          value = var.proxy_manager
        }
      ]
    }
  ])

  tags = {
    "source"  = "rssnyder/terraform-aws-harness-delegate-ecs-fargate",
    "cluster" = var.cluster_id != "" ? var.cluster_id : aws_ecs_cluster.this[0].id
  }
}

resource "aws_ecs_task_definition" "delegate-runner" {
  count = local.runner_config != "" ? 1 : 0

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  family                   = "harness-ng-delegate-runner"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions = jsonencode([
    {
      name      = "ecs-delegate"
      image     = var.delegate_image
      essential = true
      memory    = 1024
      repositoryCredentials = var.registry_secret_arn != "" ? {
        credentialsParameter = var.registry_secret_arn
      } : null,
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "ecs/delegate"
        }
      },
      secrets = [
        {
          name      = "DELEGATE_TOKEN",
          valueFrom = "${var.delegate_token_secret_arn}:::"
        }
      ],
      environment = [
        {
          name  = "ACCOUNT_ID",
          value = var.harness_account_id
        },
        {
          name  = "DELEGATE_CHECK_LOCATION",
          value = var.delegate_check_location
        },
        {
          name  = "DELEGATE_STORAGE_URL",
          value = var.delegate_storage_url
        },
        {
          name  = "LOG_STREAMING_SERVICE_URL",
          value = var.log_streaming_service_url
        },
        {
          name  = "DELEGATE_TYPE",
          value = "DOCKER"
        },
        {
          name  = "INIT_SCRIPT",
          value = var.init_script
        },
        {
          name  = "DEPLOY_MODE",
          value = "KUBERNETES"
        },
        {
          name  = "MANAGER_HOST_AND_PORT",
          value = var.manager_host_and_port
        },
        {
          name  = "WATCHER_CHECK_LOCATION",
          value = var.watcher_check_location
        },
        {
          name  = "WATCHER_STORAGE_URL",
          value = var.watcher_storage_url
        },
        {
          name  = "CDN_URL",
          value = var.cdn_url
        },
        {
          name  = "REMOTE_WATCHER_URL_CDN",
          value = var.remote_watcher_url_cdn
        },
        {
          name  = "DELEGATE_NAME",
          value = var.name
        },
        {
          name  = "NEXT_GEN",
          value = "true"
        },
        {
          name  = "DELEGATE_DESCRIPTION",
          value = var.delegate_description
        },
        {
          name  = "DELEGATE_TAGS",
          value = var.delegate_tags
        },
        {
          name  = "PROXY_MANAGER",
          value = var.proxy_manager
        }
      ]
    },
    {
      name             = "drone-runner"
      image            = var.runner_image
      essential        = false
      memory           = 1024
      entrypoint       = ["/bin/drone-runner-aws", "delegate", "--pool", "pool.yml"]
      workingDirectory = "/runner"
      repositoryCredentials = var.registry_secret_arn != "" ? {
        credentialsParameter = var.registry_secret_arn
      } : {},
      dependsOn = [{
        containerName = "create-runner-config",
        condition     = "SUCCESS"
      }]
      mountPoints = [{
        containerPath = "/runner",
        sourceVolume  = "runner-config"
      }]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "ecs/runner"
        }
      },
      portMappings : [
        {
          "containerPort" : 3000,
          "hostPort" : 3000
        }
      ]
    },
    {
      name      = "create-runner-config"
      image     = "rssnyder/base64-to-file"
      essential = false
      memory    = 1024
      repositoryCredentials = var.registry_secret_arn != "" ? {
        credentialsParameter = var.registry_secret_arn
      } : {},
      mountPoints = [{
        containerPath = "/data",
        sourceVolume  = "runner-config"
      }]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "ecs/create-runner-config"
        }
      },
      environment = [
        {
          name  = "BASE64_FILE",
          value = local.runner_config
        },
        {
          name  = "FILENAME",
          value = "pool.yml"
        },
      ]
    }
  ])

  volume {
    name = "runner-config"

    efs_volume_configuration {
      file_system_id          = aws_efs_file_system.runner[0].id
      root_directory          = "/"
      transit_encryption      = "ENABLED"
      transit_encryption_port = 2999
      authorization_config {
        access_point_id = aws_efs_access_point.runner[0].id
        iam             = "ENABLED"
      }
    }
  }

  tags = {
    "source"  = "rssnyder/terraform-aws-harness-delegate-ecs-fargate",
    "cluster" = var.cluster_id != "" ? var.cluster_id : aws_ecs_cluster.this[0].id
  }
}

resource "aws_ecs_service" "this" {
  name                   = "harness-delegate-${var.name}"
  cluster                = var.cluster_id != "" ? var.cluster_id : aws_ecs_cluster.this[0].id
  task_definition        = local.runner_config != "" ? aws_ecs_task_definition.delegate-runner[0].arn : aws_ecs_task_definition.delegate[0].arn
  desired_count          = 1
  launch_type            = "FARGATE"
  scheduling_strategy    = "REPLICA"
  enable_execute_command = var.enable_ecs_exec

  network_configuration {
    security_groups  = var.security_groups
    subnets          = var.subnets
    assign_public_ip = false
  }
}
