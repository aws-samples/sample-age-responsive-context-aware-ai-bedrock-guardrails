# Age-Responsive AI Module - Main Configuration
# Enterprise-grade modular Terraform structure

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# Resources are organized in separate files:
# - advanced_guardrails.tf: 5 Bedrock Guardrails with specialized configurations
# - lambda.tf: Lambda function with VPC configuration
# - api_gateway.tf: API Gateway with JWT authorization
# - cognito.tf: User authentication and management
# - dynamodb.tf: User profiles and audit logging
# - vpc.tf: Network isolation and security
# - waf.tf: Web Application Firewall protection
# - cloudwatch.tf: Monitoring and logging
# - kms.tf: Encryption key management
# - random.tf: Random ID generation
# - iam_access_analyzer.tf: IAM Access Analyzer (commented)
# - populate_users.tf: User population (commented)
# - data.tf: Data sources and lookups
# - variables.tf: Input variables
# - outputs.tf: Module outputs