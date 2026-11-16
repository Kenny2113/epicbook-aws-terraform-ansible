output "ec2_public_ip" {
  description = "Public IPv4 address of the EpicBook application server"
  value       = aws_instance.web.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS name of the EpicBook application server"
  value       = aws_instance.web.public_dns
}

output "ssh_command" {
  description = "SSH command for connecting to the application server"
  value       = "ssh -i ~/.ssh/epicbook-prod-key ubuntu@${aws_instance.web.public_ip}"
}

output "db_host" {
  description = "Private endpoint address of the MySQL database"
  value       = aws_db_instance.epicbook.address
}

output "db_name" {
  description = "EpicBook database name"
  value       = aws_db_instance.epicbook.db_name
}

output "db_username" {
  description = "MySQL database username"
  value       = aws_db_instance.epicbook.username
}
