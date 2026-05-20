# outputs.tf

output "rds_endpoint" {
  description = "The connection endpoint for the RDS instance"
  value       = aws_db_instance.jpx_database.endpoint
}

output "bastion_public_ip" {
  description = "The public IP address of the bastion host"
  value       = aws_instance.jpx_bastion.public_ip
}