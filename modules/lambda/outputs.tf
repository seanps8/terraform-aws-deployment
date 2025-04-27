output "invoke_arn" {
  description = "Lambda invoke arn"
  value = aws_lambda_function.lambda_function.invoke_arn
}

output "function_name" {
  description = "Lambda function name"
  value = aws_lambda_function.lambda_function.function_name
}

output "lambda_sg_id" {
  description = "lambda sg id"
  value = aws_security_group.lambda_sg.id
}