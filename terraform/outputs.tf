output "api_url" {
  description = "API Gateway URL for the /ask endpoint"
  value       = "${aws_apigatewayv2_stage.stage.invoke_url}/ask"
}

output "web_demo_setup" {
  description = "Instructions for setting up the web demo"
  value       = "cd web-demo && python3 -m http.server 8080 && open http://localhost:8080"
}

output "user_table" {
  description = "DynamoDB Users table name"
  value       = aws_dynamodb_table.users.name
}

output "audit_table" {
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

output "jwt_generator" {
  description = "Generate JWT tokens for testing"
  value       = "cd utils && python3 generate_jwt.py <user_id>"
}

output "guardrail_id" {
  description = "Bedrock Guardrail ID"
  value       = aws_bedrock_guardrail.demo_guardrail.guardrail_id
}

# API Key output removed - not compatible with HTTP API v2

output "dlq_url" {
  description = "Dead Letter Queue URL"
  value       = aws_sqs_queue.lambda_dlq.url
}

output "kms_key_id" {
  description = "KMS Key ID for Lambda encryption"
  value       = aws_kms_key.lambda_env_key.key_id
}

output "test_commands" {
  description = "Test commands to verify the deployment (requires JWT token)"
  value = <<-EOT
# 1. Generate JWT token first:
cd utils && python3 generate_jwt.py student-123

# 2. Test the API with JWT (replace <TOKEN> with output from step 1):
curl -X POST ${aws_apigatewayv2_stage.stage.invoke_url}/ask \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{"query":"What is DNA?"}'

# 3. Test with different user:
cd utils && python3 generate_jwt.py provider-101
curl -X POST ${aws_apigatewayv2_stage.stage.invoke_url}/ask \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{"query":"What is DNA?"}'
EOT
}
