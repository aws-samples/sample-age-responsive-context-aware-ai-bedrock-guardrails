# KMS Key for CloudWatch Logs
resource "aws_kms_key" "cloudwatch_logs_key" {
  description         = "KMS key for CloudWatch Logs encryption"
  enable_key_rotation = true
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${var.region}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/apigateway/responsive-ai-demo"
          }
        }
      }
    ]
  })
  
  tags = {
    Name        = "ResponsiveAI-CloudWatch-KMS"
    Environment = "production"
    Purpose     = "CloudWatch Logs encryption"
  }
}

resource "aws_kms_alias" "cloudwatch_logs_key_alias" {
  name          = "alias/cloudwatch-logs-key"
  target_key_id = aws_kms_key.cloudwatch_logs_key.key_id
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/responsive-ai-demo"
  retention_in_days = 14
  kms_key_id        = aws_kms_key.cloudwatch_logs_key.arn
  
  tags = {
    Name        = "ResponsiveAI-API-Logs"
    Environment = "production"
    Purpose     = "API Gateway access logs"
  }
}

# API Gateway Resources
resource "aws_apigatewayv2_api" "api" {
  name          = "responsive-ai-demo-api"
  protocol_type = "HTTP"
  
  cors_configuration {
    allow_credentials = false
    allow_headers     = ["content-type", "x-requested-with", "authorization"]
    allow_methods     = ["POST", "OPTIONS"]
    allow_origins     = ["*"]
    max_age          = 86400
  }
  
  tags = {
    Name        = "ResponsiveAI-API"
    Environment = "production"
    Purpose     = "Context-aware AI API"
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id             = aws_apigatewayv2_api.api.id
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.fn.invoke_arn
  integration_method = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /ask"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

# Note: API Keys and Usage Plans are not compatible with HTTP API (v2)
# They would require REST API (v1) instead

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "prod"
  auto_deploy = true
  
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      routeKey       = "$context.routeKey"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      error          = "$context.error.message"
      integrationError = "$context.integration.error"
    })
  }
  
  tags = {
    Name        = "ResponsiveAI-API-Stage"
    Environment = "production"
    Purpose     = "Production API stage"
  }
}