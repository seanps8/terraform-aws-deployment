variable "aws_region" {
  description = "AWS region to deploy"
  type = string
}

variable "aws_profile" {
  description = "AWS profile credentials to use"
  type = string
  default = "default"
}

variable "db_password" {
  description = "RDS db password"
  type = string
}

variable "db_user" {
  description = "RDS db password"
  type = string
}

variable "state_bucket" {
  description = "Name of S3 bucket to store Terraform state"
  type        = string
}

variable "state_key" {
  description = "Path/key in S3 bucket for Terraform state file"
  type        = string
}