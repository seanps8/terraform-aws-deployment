resource "aws_s3_bucket" "data_bucket" {
  bucket = "sean-terraform-challenge-bucket"
}

resource "aws_s3_bucket_public_access_block" "bucket_public_block" {
  bucket                  = aws_s3_bucket.data_bucket.bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_db_subnet_group" "rds_subnets" {
  name       = "rds-subnet-group"
  subnet_ids =  var.subnet_ids
  tags = {
    Name = "RDS Subnet Group"
  }
}

resource "aws_db_instance" "db" {
  allocated_storage       = 20
  storage_type            = "gp2"
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t2.micro"
  db_name                 = "terraform-challenge-db"
  username                = var.db_user
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.rds_subnets.name
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
}