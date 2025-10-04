# IAM Role for Lambda functions
resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-${var.environment}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-lambda-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Policy for Lambda to access CloudWatch Logs
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.lambda_role.name
}

# IAM Policy for Lambda to access Secrets Manager
resource "aws_iam_policy" "lambda_secrets_policy" {
  name = "${var.project_name}-${var.environment}-lambda-secrets-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_secretsmanager_secret.jwt_secret.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_secrets_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_secrets_policy.arn
  role       = aws_iam_role.lambda_role.name
}

# IAM Role for API Gateway
resource "aws_iam_role" "api_gateway_role" {
  name = "${var.project_name}-${var.environment}-api-gateway-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for API Gateway to invoke Lambda
resource "aws_iam_policy" "api_gateway_lambda_policy" {
  name = "${var.project_name}-${var.environment}-api-gateway-lambda-policy"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = [
          aws_lambda_function.auth_lambda.arn,
          aws_lambda_function.validate_lambda.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_lambda_policy_attachment" {
  policy_arn = aws_iam_policy.api_gateway_lambda_policy.arn
  role       = aws_iam_role.api_gateway_role.name
}