data "aws_region" "current" {}


resource "aws_cloudwatch_log_group" "this" {
  name = "harness-delegate-${var.name}"
}

resource "aws_ecs_cluster" "this" {
  count = var.cluster_id ? 0 : 1

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

resource "aws_iam_role_policy_attachment" "task_execution" {
  role       = aws_iam_role.task_execution.name
  policy_arn = aws_iam_policy.task_execution.arn
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
}

resource "aws_iam_role_policy_attachment" "task" {
  count = var.delegate_policy_arn ? 0 : 1

  role       = aws_iam_role.task.name
  policy_arn = var.delegate_policy_arn
}

resource "aws_ecs_task_definition" "this" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  family                   = "harness-ng-delegate"
  cpu                      = 1024
  memory                   = 2048
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn
  container_definitions = jsonencode([{
    name      = "ecs-delegate"
    image     = "harness/delegate:latest"
    essential = true
    memory    = 2048
    logConfiguration = {
      logDriver = "awslogs",
      options = {
        awslogs-group         = aws_cloudwatch_log_group.this.name,
        awslogs-region        = data.aws_region.current.name,
        awslogs-stream-prefix = "ecs"
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
        value = ""
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
  }])
}

resource "aws_ecs_service" "this" {
  name                = "harness-delegate-${var.name}"
  cluster             = var.cluster_id ? var.cluster_id : aws_ecs_cluster.this[0].id
  task_definition     = aws_ecs_task_definition.this.arn
  desired_count       = 1
  launch_type         = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    security_groups  = var.security_groups
    subnets          = var.subnets
    assign_public_ip = false
  }
}
