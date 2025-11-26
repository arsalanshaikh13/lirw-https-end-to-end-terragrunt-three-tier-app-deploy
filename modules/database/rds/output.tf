output "db_dns_address" {
  description = "dns address for db instance endpoint"
  value       = aws_db_instance.lirw-database.address
}

output "db_endpoint" {
  description = "db instance  endpoint for db instance"
  value = aws_db_instance.lirw-database.endpoint
}

output "db_username" {
  description = "db instance  username for db instance"
  value = aws_db_instance.lirw-database.username
}
output "db_password" {
  description = "db instance  password for db instance"
  value = aws_db_instance.lirw-database.password
  sensitive = true
}


