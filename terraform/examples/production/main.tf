# Age-Responsive AI with Bedrock Guardrails - Production Example
# Main implementation that calls the reusable module

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# Call the Age-Responsive AI module
module "age_responsive_ai" {
  source = "../../modules/age-responsive-ai"

  # Project Configuration
  project_name = var.project_name
  environment  = var.environment
  region       = var.region

  # Bedrock Configuration
  bedrock_model_id = var.bedrock_model_id

  # Component Configurations
  lambda_config      = var.lambda_config
  api_gateway_config = var.api_gateway_config
  dynamodb_config    = var.dynamodb_config
  waf_config         = var.waf_config
  cloudwatch_config  = var.cloudwatch_config
  # vpc_config         = var.vpc_config  # Removed - using default network
  cognito_config     = var.cognito_config

  # Common Tags
  common_tags = var.common_tags
}