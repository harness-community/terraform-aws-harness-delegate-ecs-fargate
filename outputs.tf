output "aws_ecs_task_definition" {
  description = "The ARN of the ECS task definition"
  value       = aws_ecs_task_definition.this.arn
}

output "aws_ecs_service" {
  description = "The ID of the ECS service"
  value       = aws_ecs_service.this.id
}
