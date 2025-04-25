output "data_bucket_id" {
  description = "The data bucket id"
  value = aws_s3_bucket.data_bucket.id
}

output "data_bucket_arn" {
  description = "The data bucket arn"
  value = aws_s3_bucket.data_bucket.arn
}

output "rds_host" {
  description = "Address of RDS instance"
  value = aws_db_instance.db.address
}

# output "db_username" {
#   description = "RDS username"
#   value = aws_db_instance.db.db_instance_username
# }

# output "db_password" {
#   description = "RDS username"
#   value = var.db_password
#   sensitive = true
# }

output "db_name" {
  description = "Database name"
  value = aws_db_instance.db.db_name
}