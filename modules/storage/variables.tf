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

variable "subnet_ids" {
  description = "Subnet ids"
  type = set(string)
}