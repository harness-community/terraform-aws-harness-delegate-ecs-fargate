output "aws_ecs_cluster" {
  description = "The ID of the ECS cluster"
  value       = length(aws_ecs_cluster.this) > 0 ? aws_ecs_cluster.this[0].id : null
}

output "aws_ecs_task_definition" {
  description = "The ARN of the ECS task definition"
  value       = aws_ecs_task_definition.this.arn
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
