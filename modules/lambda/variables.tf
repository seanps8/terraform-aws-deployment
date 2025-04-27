variable "rds_host" {
  description = "RDS host address"
  type = string
}

variable "db_password" {
  description = "RDS DB password"
  type = string
  sensitive = true
}

variable "db_user" {
  description = "RDS DB user"
  type = string
  sensitive = true
}

variable "db_name" {
  description = "RDS DB name"
  type = string
}

variable "subnet_ids" {
  description = "Subnet ids"
  type = set(string)
}

variable "vpc_id" {
  description = "VPC id"
  type = string
}

variable "data_bucket_id" {
  description = "s3 data bucket id"
  type = string
}

variable "data_bucket_arn" {
  description = "s3 data bucket arn"
  type = string
}

variable "data_bucket_name" {
  description = "s3 data bucket name"
  type = string
}