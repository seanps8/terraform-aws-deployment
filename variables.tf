variable "aws_region" {
  description = "AWS region to deploy"
  type = string
}

variable "aws_profile" {
  description = "AWS profile credentials to use"
  type = string
  default = "default"
}

# variable "aws_account_id" {
#   description = "AWS account ID"
#   type = string
# }

variable "db_password" {
  description = "RDS db password"
  type = string
}

variable "db_user" {
  description = "RDS db password"
  type = string
}