# Lambda Function Resources - Age-Responsive AI Module
# Reusable Lambda configuration with Bedrock Guardrails integration

# Lambda IAM Role
resource "aws_iam_role" "lambda_role" {
  name               = "${local.name_prefix}-lambda-role-${local.suffix}"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
  
  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-lambda-role"
    Purpose = "Lambda execution role"
  })
}

# Lambda execution policy
resource "aws_iam_role_policy" "lambda_exec" {
  name = "${local.name_prefix}-lambda-policy"
  role = aws_iam_role.lambda_role.id
  
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
        Resource = [
          "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${local.name_prefix}-*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${data.aws_region.current.name}::foundation-model/${var.bedrock_model_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:ApplyGuardrail"
        ]
        Resource = [
          aws_bedrock_guardrail.child_protection.guardrail_arn,
          aws_bedrock_guardrail.teen_educational.guardrail_arn,
          aws_bedrock_guardrail.healthcare_professional.guardrail_arn,
          aws_bedrock_guardrail.healthcare_patient.guardrail_arn,
          aws_bedrock_guardrail.adult_general.guardrail_arn
        ]
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
          aws_dynamodb_table.audit.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = [
          aws_kms_key.main.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = "*"
      }
    ]
  })
}


# Lambda deployment package
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.root}/../../../lambda/package"
  output_path = "${path.root}/../../../lambda/app.zip"
}

# Lambda function
resource "aws_lambda_function" "main" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "${local.name_prefix}-function-${local.suffix}"
  handler          = "app.lambda_handler"
  runtime          = var.lambda_config.runtime
  role            = aws_iam_role.lambda_role.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  timeout         = var.lambda_config.timeout
  memory_size     = var.lambda_config.memory_size
  architectures   = [var.lambda_config.architecture]
  
  reserved_concurrent_executions = 20


  # Environment variables with KMS encryption
  environment {
    variables = {
      # Bedrock Guardrail IDs for Dynamic Selection
      CHILD_GUARDRAIL_ID                  = aws_bedrock_guardrail.child_protection.guardrail_id
      TEEN_GUARDRAIL_ID                   = aws_bedrock_guardrail.teen_educational.guardrail_id
      HEALTHCARE_PROFESSIONAL_GUARDRAIL_ID = aws_bedrock_guardrail.healthcare_professional.guardrail_id
      HEALTHCARE_PATIENT_GUARDRAIL_ID     = aws_bedrock_guardrail.healthcare_patient.guardrail_id
      ADULT_GENERAL_GUARDRAIL_ID          = aws_bedrock_guardrail.adult_general.guardrail_id
      DEFAULT_GUARDRAIL_ID                = aws_bedrock_guardrail.adult_general.guardrail_id
      
      # Database tables
      USER_TABLE  = aws_dynamodb_table.users.name
      AUDIT_TABLE = aws_dynamodb_table.audit.name
    }
  }
  
  kms_key_arn = aws_kms_key.main.arn
  
  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-lambda"
    Purpose = "Age-responsive AI processing with Bedrock Guardrails"
  })

  depends_on = [
    aws_iam_role_policy.lambda_exec,
    # aws_iam_role_policy_attachment.lambda_vpc,  # Temporarily disabled
    aws_cloudwatch_log_group.lambda
  ]
}