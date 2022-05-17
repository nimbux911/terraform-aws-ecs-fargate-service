output "service_name" {
  description = "Service name"
  value       = aws_ecs_service.main.name
}