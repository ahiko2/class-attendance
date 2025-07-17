output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.backend.id
}

output "public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.backend_eip.public_ip
}

output "public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.backend.public_dns
}

output "private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.backend.private_ip
}
