output "api_gateway_url" {
  description = "API Gateway URL"
  value       = aws_api_gateway_deployment.main.invoke_url
}

output "auth_lambda_function_name" {
  description = "Auth Lambda function name"
  value       = aws_lambda_function.auth_lambda.function_name
}

output "validate_lambda_function_name" {
  description = "Validate Lambda function name"
  value       = aws_lambda_function.validate_lambda.function_name
}

output "jwt_secret_arn" {
  description = "JWT Secret ARN in Secrets Manager"
  value       = aws_secretsmanager_secret.jwt_secret.arn
}

output "public_endpoints" {
  description = "Public API endpoints"
  value = {
    auth = "${aws_api_gateway_deployment.main.invoke_url}/auth"
  }
}

output "private_endpoints" {
  description = "Private API endpoints (require JWT)"
  value = {
    protected = "${aws_api_gateway_deployment.main.invoke_url}/protected"
    eks_proxy = "${aws_api_gateway_deployment.main.invoke_url}/eks"
  }
}