# Lambda Function Resources
resource "aws_iam_role" "lambda_role" {
  name               = "lambda_bedrock_role"
  assume_role_policy = data.aws_iam_policy_document.trust.json
  
  tags = {
    Name        = "ResponsiveAI-Lambda-Role"
    Environment = "production"
    Purpose     = "Lambda execution role"
  }
}

resource "aws_iam_role_policy" "lambda_exec" {
  name   = "lambda_exec_policy"
  role   = aws_iam_role.lambda_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:ApplyGuardrail"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query"
        ]
        Resource = [
          aws_dynamodb_table.users.arn,
          aws_dynamodb_table.audit.arn,
          "${aws_dynamodb_table.audit.arn}/index/*"
        ]
      }
    ]
  })
}

# Additional permissions for X-Ray, SQS, and KMS
resource "aws_iam_role_policy" "lambda_additional" {
  name = "lambda_additional_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.lambda_dlq.arn
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.lambda_env_key.arn,
          aws_kms_key.dynamodb_key.arn
        ]
      }
    ]
  })
}

# Create Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/../lambda/package"
  output_path = "${path.module}/../lambda/app.zip"
}

# KMS Key for Lambda environment encryption
resource "aws_kms_key" "lambda_env_key" {
  description         = "KMS key for Lambda environment variables"
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
        Sid    = "Allow Lambda Service"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "lambda.${var.region}.amazonaws.com"
          }
        }
      }
    ]
  })
  
  tags = {
    Name        = "ResponsiveAI-Lambda-KMS"
    Environment = "production"
    Purpose     = "Lambda environment encryption"
  }
}

resource "aws_kms_alias" "lambda_env_key_alias" {
  name          = "alias/lambda-env-key"
  target_key_id = aws_kms_key.lambda_env_key.key_id
}

# SQS DLQ for Lambda
resource "aws_sqs_queue" "lambda_dlq" {
  name                       = "responsive-ai-demo-dlq"
  kms_master_key_id         = aws_kms_key.lambda_env_key.arn
  kms_data_key_reuse_period_seconds = 300
  
  tags = {
    Name        = "ResponsiveAI-DLQ"
    Environment = "production"
    Purpose     = "Lambda dead letter queue"
  }
}

resource "aws_lambda_function" "fn" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "responsive_ai_demo"
  handler          = "app.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout          = 15
  memory_size      = 256
  reserved_concurrent_executions = 10

  # X-Ray tracing
  tracing_config {
    mode = "Active"
  }

  # Dead Letter Queue
  dead_letter_config {
    target_arn = aws_sqs_queue.lambda_dlq.arn
  }

  # Encrypted environment variables
  environment {
    variables = {
      GUARDRAIL_ID = aws_bedrock_guardrail.demo_guardrail.guardrail_id
      USER_TABLE = aws_dynamodb_table.users.name
      AUDIT_TABLE = aws_dynamodb_table.audit.name
      JWT_SECRET = var.jwt_secret
    }
  }
  
  kms_key_arn = aws_kms_key.lambda_env_key.arn
  
  tags = {
    Name        = "ResponsiveAI-Lambda"
    Environment = "production"
    Purpose     = "Context-aware AI processing"
  }
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.fn.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}