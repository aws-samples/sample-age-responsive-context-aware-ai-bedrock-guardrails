# Age-Responsive AI Module Outputs
# Comprehensive outputs for integration and monitoring

output "api_url" {
  description = "API Gateway URL for the /ask endpoint"
  value       = "${aws_api_gateway_stage.main.invoke_url}/ask"
}

output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = "${aws_api_gateway_stage.main.invoke_url}/ask"
}

output "lambda_function_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.main.function_name
}

output "lambda_function_arn" {
  description = "Lambda function ARN"
  value       = aws_lambda_function.main.arn
}

output "dynamodb_tables" {
  description = "DynamoDB table names"
  value = {
    users = aws_dynamodb_table.users.name
    audit = aws_dynamodb_table.audit.name
  }
}

output "user_table" {
  description = "DynamoDB Users table name"
  value       = aws_dynamodb_table.users.name
}

output "dynamodb_users_table_name" {
  description = "DynamoDB Users table name"
  value       = aws_dynamodb_table.users.name
}

output "audit_table" {
  description = "DynamoDB Audit table name"
  value       = aws_dynamodb_table.audit.name
}

output "dynamodb_audit_table_name" {
  description = "DynamoDB Audit table name"
  value       = aws_dynamodb_table.audit.name
}

output "sample_users" {
  description = "Sample users for testing"
  value = {
    student = "student-123 (8th grade student)"
    teacher = "teacher-456 (Math teacher)"
    patient = "patient-789 (Healthcare patient)"
    provider = "provider-101 (Healthcare provider)"
  }
}

# Advanced Guardrail Outputs
output "guardrail_child_protection" {
  description = "Child Protection Guardrail details"
  value = {
    id      = aws_bedrock_guardrail.child_protection.guardrail_id
    arn     = aws_bedrock_guardrail.child_protection.guardrail_arn
    version = aws_bedrock_guardrail_version.child_protection_v1.version
  }
}

output "guardrail_teen_educational" {
  description = "Teen Educational Guardrail details"
  value = {
    id      = aws_bedrock_guardrail.teen_educational.guardrail_id
    arn     = aws_bedrock_guardrail.teen_educational.guardrail_arn
    version = aws_bedrock_guardrail_version.teen_educational_v1.version
  }
}

output "guardrail_healthcare_professional" {
  description = "Healthcare Professional Guardrail details"
  value = {
    id      = aws_bedrock_guardrail.healthcare_professional.guardrail_id
    arn     = aws_bedrock_guardrail.healthcare_professional.guardrail_arn
    version = aws_bedrock_guardrail_version.healthcare_professional_v1.version
  }
}

output "guardrail_healthcare_patient" {
  description = "Healthcare Patient Guardrail details"
  value = {
    id      = aws_bedrock_guardrail.healthcare_patient.guardrail_id
    arn     = aws_bedrock_guardrail.healthcare_patient.guardrail_arn
    version = aws_bedrock_guardrail_version.healthcare_patient_v1.version
  }
}

output "guardrail_adult_general" {
  description = "Adult General Guardrail details"
  value = {
    id      = aws_bedrock_guardrail.adult_general.guardrail_id
    arn     = aws_bedrock_guardrail.adult_general.guardrail_arn
    version = aws_bedrock_guardrail_version.adult_general_v1.version
  }
}

output "bedrock_guardrails" {
  description = "All Bedrock Guardrails information"
  value = {
    child_protection        = {
      id      = aws_bedrock_guardrail.child_protection.guardrail_id
      arn     = aws_bedrock_guardrail.child_protection.guardrail_arn
      version = aws_bedrock_guardrail_version.child_protection_v1.version
    }
    teen_educational       = {
      id      = aws_bedrock_guardrail.teen_educational.guardrail_id
      arn     = aws_bedrock_guardrail.teen_educational.guardrail_arn
      version = aws_bedrock_guardrail_version.teen_educational_v1.version
    }
    healthcare_professional = {
      id      = aws_bedrock_guardrail.healthcare_professional.guardrail_id
      arn     = aws_bedrock_guardrail.healthcare_professional.guardrail_arn
      version = aws_bedrock_guardrail_version.healthcare_professional_v1.version
    }
    healthcare_patient     = {
      id      = aws_bedrock_guardrail.healthcare_patient.guardrail_id
      arn     = aws_bedrock_guardrail.healthcare_patient.guardrail_arn
      version = aws_bedrock_guardrail_version.healthcare_patient_v1.version
    }
    adult_general         = {
      id      = aws_bedrock_guardrail.adult_general.guardrail_id
      arn     = aws_bedrock_guardrail.adult_general.guardrail_arn
      version = aws_bedrock_guardrail_version.adult_general_v1.version
    }
  }
}

# Legacy guardrail output for backward compatibility
output "guardrail_id" {
  description = "Default Bedrock Guardrail ID (Adult General)"
  value       = aws_bedrock_guardrail.adult_general.guardrail_id
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  description = "Cognito User Pool Client ID (legacy compatibility)"
  value       = aws_cognito_user_pool_client.main.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.main.id
}


output "kms_key_id" {
  description = "KMS key ID for encryption"
  value       = aws_kms_key.main.id
}

output "kms_key_arn" {
  description = "KMS key ARN for encryption"
  value       = aws_kms_key.main.arn
}

output "waf_web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.main.id
}

output "waf_web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.main.arn
}

output "cloudwatch_log_group_name" {
  description = "CloudWatch Log Group name for Lambda"
  value       = aws_cloudwatch_log_group.lambda.name
}

output "project_info" {
  description = "Project information"
  value = {
    name        = var.project_name
    environment = var.environment
    region      = var.region
    suffix      = local.suffix
  }
}