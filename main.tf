resource "aws_cloudwatch_log_group" "this" {
  name = "harness/delegate/${var.name}"

  tags = var.tags
}

resource "aws_ecs_cluster" "this" {
  count = var.cluster_id != null ? 0 : 1

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

  tags = var.tags
}

locals {
  cluster_id = var.cluster_id != null ? var.cluster_id : aws_ecs_cluster.this[0].id
  secrets    = compact([local.delegate_token_secret_arn, var.postgres_password_secret_arn, var.registry_secret_arn])
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
     "Sid": "ecstaskexecution"
   }
 ]
}
EOF

  tags = merge(var.tags, {
    "cluster" = local.cluster_id
  })
}

resource "aws_iam_policy" "task_execution_logs" {
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
        }
    ]
}
EOF

  tags = merge(var.tags, {
    "cluster" = local.cluster_id
  })
}

resource "aws_iam_policy" "task_execution_secrets" {
  count = length(local.secrets) > 0 ? 1 : 0

  name        = "${aws_iam_role.task_execution.name}_secrets"
  description = "Policy for execution of the delegate container in ecs to retirive necessary secrets"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
           "Sid": "RegistryLogin",
           "Effect": "Allow",
           "Action": "secretsmanager:GetSecretValue",
           "Resource": ${jsonencode(local.secrets)}
       }
    ]
}
EOF


  tags = merge(var.tags, {
    "cluster" = local.cluster_id
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_logs" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution_logs.arn
}

resource "aws_iam_role_policy_attachment" "task_execution_secrets" {
  count = length(local.secrets) > 0 ? 1 : 0

  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution_secrets[0].arn
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

  tags = merge(var.tags, {
    "cluster" = local.cluster_id
  })
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

  tags = merge(var.tags, {
    "cluster" = local.cluster_id
  })
}

resource "aws_iam_role_policy_attachment" "task_exec" {
  count = var.enable_ecs_exec ? 1 : 0

  role       = aws_iam_role.task.name
  policy_arn = aws_iam_policy.task_exec[0].arn
}

locals {
  delegate_environment = concat([
    {
      name  = "ACCOUNT_ID",
      value = local.harness_account_id
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
    ], local.delegate_token != null ? [
    {
      name  = "DELEGATE_TOKEN",
      value = local.delegate_token
    }
    ] : [],
  var.delegate_environment)
}

resource "aws_ecs_task_definition" "delegate" {
  count = var.runner_config != "" ? 0 : 1

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  family                   = "harness-ng-delegate"
  cpu                      = var.cpu
  memory                   = var.memory
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
      secrets = local.delegate_token_secret_arn != null ? [
        {
          name      = "DELEGATE_TOKEN",
          valueFrom = "${local.delegate_token_secret_arn}:::"
        }
      ] : [],
      environment = local.delegate_environment,
      healthCheck : {
        "command" : [
          "CMD-SHELL",
          "curl -f localhost:3460/api/health || exit 1"
        ]
      }
    }
  ])

  tags = merge(var.tags, {
    "cluster" = local.cluster_id
  })
}

locals {
  runner_environment = concat([
    {
      name  = "POOL_CONFIG",
      value = var.runner_config
    },
    {
      name  = "DEBUG",
      value = var.runner_debug
    },
    {
      name  = "NAME",
      value = var.name
    },
    {
      name  = "PARALLEL_WORKERS",
      value = var.runner_parallel_workers
    },
    {
      name  = "POLL_INTERVAL_MILLISECS",
      value = var.runner_poll_interval
    },
    {
      name  = "SKIP_PREPARE_SERVER",
      value = var.runner_skip_prepare_server
    },
    {
      name  = "TRACE",
      value = var.runner_trace
    },
    {
      name  = "ACCOUNT_ID",
      value = local.harness_account_id
    },
    {
      name  = "DRONE_DATABASE_DRIVER",
      value = var.postgres_host != null ? "postgres" : "sqlite3"
    },
    {
      name  = "DRONE_RUNNER_HA",
      value = var.runner_ha_enabled
    },
    {
      name  = "DRONE_DELEGATE_DISTRIBUTED_MODE",
      value = var.runner_distributed_mode
    },
    {
      name  = "DRONE_DATABASE_DATASOURCE",
      value = var.postgres_host != null ? "host=${var.postgres_host} user=${var.postgres_user} password=${var.postgres_password} dbname=${var.postgres_database} sslmode=${var.postgres_ssl_mode} port=${var.postgres_port}" : var.runner_database_datasource
    }
    ],
  var.runner_environment)
}

resource "aws_ecs_task_definition" "delegate-runner" {
  count = var.runner_config != "" ? 1 : 0

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  family                   = "harness-ng-delegate-runner"
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions = jsonencode([
    {
      name      = "ecs-delegate"
      image     = var.delegate_image
      essential = true
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
      secrets = local.delegate_token_secret_arn != null ? [
        {
          name      = "DELEGATE_TOKEN",
          valueFrom = "${local.delegate_token_secret_arn}:::"
        }
      ] : [],
      environment = local.delegate_environment
    },
    {
      name       = "harness-vm-runner"
      image      = var.runner_image
      entryPoint = ["/bin/sh", "-c"]
      command = [
        "mkdir -p /tmp/config && echo \"$POOL_CONFIG\" > /tmp/config/pool.yml && /bin/harness-vm-runner delegate --pool /tmp/config/pool.yml"
      ]
      essential = false
      user      = "nobody"
      repositoryCredentials = var.registry_secret_arn != "" ? {
        credentialsParameter = var.registry_secret_arn
      } : null
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          awslogs-group         = aws_cloudwatch_log_group.this.name,
          awslogs-region        = data.aws_region.current.name,
          awslogs-stream-prefix = "ecs/harness-vm-runner"
        }
      },
      portMappings = [
        {
          containerPort = 3000,
          hostPort      = 3000
        }
      ],
      secrets = var.postgres_password_secret_arn != null ? [
        {
          name      = "POSTGRES_PASSWORD",
          valueFrom = "${var.postgres_password_secret_arn}:::"
        }
      ] : [],
      environment = local.runner_environment,
      healthCheck = {
        command = [
          "CMD-SHELL",
          "curl -f http://localhost:3000/healthz || exit 1"
        ],
        interval    = 30,
        timeout     = 5,
        retries     = 3,
        startPeriod = 60
      }
    }
  ])

  tags = merge({
    cluster = local.cluster_id
  }, var.tags)
}

resource "aws_ecs_service" "this" {
  name                   = "harness-delegate-${var.name}"
  cluster                = local.cluster_id
  task_definition        = var.runner_config != "" ? aws_ecs_task_definition.delegate-runner[0].arn : aws_ecs_task_definition.delegate[0].arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  scheduling_strategy    = "REPLICA"
  enable_execute_command = var.enable_ecs_exec

  network_configuration {
    security_groups  = var.security_groups
    subnets          = var.subnets
    assign_public_ip = false
  }
}
