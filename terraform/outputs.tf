output "staging_public_ip" {
  description = "Public IP of staging instance"
  value       = aws_instance.staging.public_ip
}

output "staging_public_dns" {
  description = "Public DNS of staging instance"
  value       = aws_instance.staging.public_dns
}

output "production_public_ip" {
  description = "Public IP of production instance"
  value       = aws_instance.production.public_ip
}

output "production_public_dns" {
  description = "Public DNS of production instance"
  value       = aws_instance.production.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.app.id
}
