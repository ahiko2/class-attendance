output "endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "port" {
  description = "RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Database name"
  value       = aws_db_instance.main.db_name
}

output "username" {
  description = "Master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.main.id
}

output "arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "hosted_zone_id" {
  description = "Route53 hosted zone ID"
  value       = aws_db_instance.main.hosted_zone_id
}

output "resource_id" {
  description = "RDS resource ID"
  value       = aws_db_instance.main.resource_id
}

output "status" {
  description = "RDS instance status"
  value       = aws_db_instance.main.status
}

output "subnet_group_name" {
  description = "DB subnet group name"
  value       = aws_db_subnet_group.main.name
}
