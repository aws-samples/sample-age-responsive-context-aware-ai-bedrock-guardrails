# Age-Responsive AI Module Variables
# Comprehensive variable definitions for the Bedrock Guardrails solution

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "age-responsive-ai"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "bedrock_model_id" {
  description = "Bedrock model identifier"
  type        = string
  default     = "anthropic.claude-3-sonnet-20240229-v1:0"
}

variable "lambda_config" {
  description = "Lambda function configuration"
  type = object({
    runtime      = string
    timeout      = number
    memory_size  = number
    architecture = string
  })
  default = {
    runtime      = "python3.11"
    timeout      = 60
    memory_size  = 1024
    architecture = "x86_64"
  }
}

variable "api_gateway_config" {
  description = "API Gateway configuration"
  type = object({
    stage_name           = string
    throttle_rate_limit  = number
    throttle_burst_limit = number
  })
  default = {
    stage_name           = "prod"
    throttle_rate_limit  = 2000
    throttle_burst_limit = 1000
  }
}

variable "dynamodb_config" {
  description = "DynamoDB configuration"
  type = object({
    billing_mode           = string
    point_in_time_recovery = bool
    users_table_name       = string
  })
  default = {
    billing_mode           = "PAY_PER_REQUEST"
    point_in_time_recovery = false
    users_table_name       = "ResponsiveAI-Users"
  }
}

variable "waf_config" {
  description = "WAF configuration"
  type = object({
    rate_limit     = number
    enable_logging = bool
  })
  default = {
    rate_limit     = 2000
    enable_logging = false
  }
}

variable "cloudwatch_config" {
  description = "CloudWatch configuration"
  type = object({
    log_retention_days    = number
    enable_kms_encryption = bool
  })
  default = {
    log_retention_days    = 30
    enable_kms_encryption = true
  }
}


variable "cognito_config" {
  description = "Cognito User Pool configuration"
  type = object({
    password_policy = object({
      minimum_length    = number
      require_lowercase = bool
      require_numbers   = bool
      require_symbols   = bool
      require_uppercase = bool
    })
    auto_verified_attributes = list(string)
    username_attributes      = list(string)
  })
  default = {
    password_policy = {
      minimum_length    = 8
      require_lowercase = true
      require_numbers   = true
      require_symbols   = true
      require_uppercase = true
    }
    auto_verified_attributes = []
    username_attributes      = []
  }
}

variable "kms_config" {
  description = "KMS encryption configuration"
  type = object({
    enable_kms_encryption = bool
  })
  default = {
    enable_kms_encryption = false
  }
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project     = "Age-Responsive-AI"
    Environment = "Production"
    Owner       = "DevOps-Team"
    CostCenter  = "AI-Innovation"
    Compliance  = "COPPA-HIPAA"
  }
}