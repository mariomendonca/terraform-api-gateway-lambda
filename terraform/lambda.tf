# Archive auth lambda source code
data "archive_file" "auth_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/auth-lambda"
  output_path = "${path.module}/auth-lambda.zip"
}

# Archive validate lambda source code
data "archive_file" "validate_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambdas/validate-lambda"
  output_path = "${path.module}/validate-lambda.zip"
}

# Auth Lambda Function
resource "aws_lambda_function" "auth_lambda" {
  filename         = data.archive_file.auth_lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-auth"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.auth_lambda_zip.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = 30

  environment {
    variables = {
      JWT_SECRET_NAME = aws_secretsmanager_secret.jwt_secret.name
      NODE_ENV       = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-auth-lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}

# Validate Lambda Function
resource "aws_lambda_function" "validate_lambda" {
  filename         = data.archive_file.validate_lambda_zip.output_path
  function_name    = "${var.project_name}-${var.environment}-validate"
  role            = aws_iam_role.lambda_role.arn
  handler         = "index.handler"
  source_code_hash = data.archive_file.validate_lambda_zip.output_base64sha256
  runtime         = var.lambda_runtime
  timeout         = 30

  environment {
    variables = {
      JWT_SECRET_NAME = aws_secretsmanager_secret.jwt_secret.name
      NODE_ENV       = var.environment
    }
  }

  tags = {
    Name        = "${var.project_name}-validate-lambda"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Groups for Lambdas
resource "aws_cloudwatch_log_group" "auth_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.auth_lambda.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-auth-lambda-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_cloudwatch_log_group" "validate_lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.validate_lambda.function_name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-validate-lambda-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}