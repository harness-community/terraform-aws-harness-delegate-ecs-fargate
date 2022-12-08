output "aws_ecs_cluster" {
  description = "The ID of the ECS cluster"
  value       = var.cluster_id != "" ? var.cluster_id : aws_ecs_cluster.this[0].id
}

output "aws_ecs_task_definition" {
  description = "The ARN of the ECS task definition"
  value       = var.base64_runner_config != "" ? aws_ecs_task_definition.delegate-runner[0].arn : aws_ecs_task_definition.delegate[0].arn
}

output "aws_ecs_service" {
  description = "The ID of the ECS service"
  value       = aws_ecs_service.this.id
}

output "aws_iam_role_task_execution" {
  description = "The IAM role for ECS execution"
  value       = aws_iam_role.task_execution.arn
}

output "aws_iam_role_task" {
  description = "The IAM role for the ECS task"
  value       = aws_iam_role.task.arn
}

output "aws_efs_file_system" {
  description = "The filesystem used for drone runner"
  value       = var.base64_runner_config != "" ? aws_efs_file_system.runner[0].arn : null
}
