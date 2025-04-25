resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_security_group" "lambda_sg" {
  name = "s3-to-RDS-lambda-sg"
  description = "Lambda sg"
  vpc_id = var.vpc_id
  tags = {
    Name = "s3-to-RDS-lambda-sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "lambda_sg_ingress" {
  ip_protocol = "-1"
  security_group_id = aws_security_group.lambda_sg.id
  referenced_security_group_id = aws_security_group.lambda_sg.id
}

resource "aws_vpc_security_group_egress_rule" "lambda_sg_egress" {
  ip_protocol = "-1"
  security_group_id = aws_security_group.lambda_sg.id
  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_lambda_function" "lambda_function" {
  filename         = "${path.root}/app/lambda.zip"
  function_name    = "s3-to-rds"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.11"
  source_code_hash = filebase64sha256("${path.root}/app/lambda.zip")

  vpc_config {
    subnet_ids = var.subnet_ids
    security_group_ids = [aws_iam_role.lambda_role.id]
  }

  environment {
    variables = {
      RDS_HOST     = var.rds_host
      DB_USERNAME  = var.db_user
      DB_PASSWORD  = var.db_password
      DB_NAME      = var.db_name
    }
  }
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = var.data_bucket_id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.data_bucket_arn
}