variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "jwt-auth-system"
}

variable "environment" {
  description = "Environment (dev, prod, staging)"
  type        = string
  default     = "dev"
}

variable "jwt_secret" {
  description = "JWT secret key"
  type        = string
  default     = "your-super-secret-jwt-key-change-this-in-production"
  sensitive   = true
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "nodejs18.x"
}