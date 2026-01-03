# Data Sources - Age-Responsive AI Module
# Common data sources used across the module

# Current AWS account and region information
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# Available AZs for subnet placement
data "aws_availability_zones" "available" {
  state = "available"
}

# Lambda trust policy document
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# Local values for consistent naming and tagging
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  suffix      = random_id.suffix.hex
  
  common_tags = merge(var.common_tags, {
    Project     = var.project_name
    Environment = var.environment
    Region      = var.region
    Module      = "age-responsive-ai"
  })
}