# Outputs - Age-Responsive AI Production Example
# Outputs from the module implementation

output "api_url" {
  description = "API Gateway URL for the /ask endpoint"
  value       = module.age_responsive_ai.api_url
}

output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = module.age_responsive_ai.api_gateway_url
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.age_responsive_ai.cognito_user_pool_id
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.age_responsive_ai.cognito_client_id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.age_responsive_ai.cognito_user_pool_client_id
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = module.age_responsive_ai.lambda_function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = module.age_responsive_ai.lambda_function_arn
}

output "dynamodb_tables" {
  description = "DynamoDB table names"
  value = {
    users = module.age_responsive_ai.dynamodb_users_table_name
    audit = module.age_responsive_ai.dynamodb_audit_table_name
  }
}

output "bedrock_guardrails" {
  description = "Bedrock Guardrails information"
  value       = module.age_responsive_ai.bedrock_guardrails
}

output "infrastructure_info" {
  description = "Infrastructure information"
  value = {
    # vpc_id              = module.age_responsive_ai.vpc_id  # Removed - using default network
    # private_subnet_ids  = module.age_responsive_ai.private_subnet_ids  # Removed
    kms_key_arn        = module.age_responsive_ai.kms_key_arn
    waf_web_acl_arn    = module.age_responsive_ai.waf_web_acl_arn
    project_info       = module.age_responsive_ai.project_info
  }
}