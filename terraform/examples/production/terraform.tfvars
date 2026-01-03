# Age-Responsive AI with Bedrock Guardrails - Production Configuration
# Configuration values for the production example

# Project Configuration
project_name = "age-responsive-ai"
environment  = "production"
region      = "us-east-1"

# Bedrock Guardrails Configuration
bedrock_model_id = "anthropic.claude-3-sonnet-20240229-v1:0"

# Lambda Configuration
lambda_config = {
  runtime       = "python3.11"
  timeout       = 60
  memory_size   = 1024
  architecture  = "x86_64"
}

# API Gateway Configuration
api_gateway_config = {
  stage_name           = "prod"
  throttle_rate_limit  = 2000
  throttle_burst_limit = 1000
}

# DynamoDB Configuration
dynamodb_config = {
  billing_mode = "PAY_PER_REQUEST"
  point_in_time_recovery = false
  users_table_name = "ResponsiveAI-Users"
}

# WAF Configuration
waf_config = {
  rate_limit = 2000
  enable_logging = false
}

# CloudWatch Configuration
cloudwatch_config = {
  log_retention_days = 30
  enable_kms_encryption = true
}

# VPC Configuration - Removed (using default AWS network)
# vpc_config = {
#   cidr_block           = "10.0.0.0/16"
#   enable_dns_hostnames = true
#   enable_dns_support   = true
#   
#   private_subnets = [
#     {
#       cidr_block        = "10.0.1.0/24"
#       availability_zone = "us-east-1a"
#     },
#     {
#       cidr_block        = "10.0.2.0/24"
#       availability_zone = "us-east-1b"
#     }
#   ]
# }

# Cognito Configuration
cognito_config = {
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

# Tags applied to all resources
common_tags = {
  Project     = "Age-Responsive-AI"
  Environment = "Production"
  Owner       = "DevOps-Team"
  CostCenter  = "AI-Innovation"
  Compliance  = "COPPA-HIPAA"
}