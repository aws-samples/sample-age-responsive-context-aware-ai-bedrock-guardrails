# KMS Keys - Age-Responsive AI Module
# Encryption keys for data protection

# Main KMS Key for encryption
resource "aws_kms_key" "main" {
  description             = "KMS key for ${local.name_prefix} encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

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
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow DynamoDB"
        Effect = "Allow"
        Principal = {
          Service = "dynamodb.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${local.name_prefix}-kms-key"
    Purpose     = "Encryption for logs DynamoDB and Lambda"
    Project     = var.project_name
    Environment = var.environment
  }
}

# KMS Key Alias
resource "aws_kms_alias" "main" {
  name          = "alias/${local.name_prefix}-key-${local.suffix}"
  target_key_id = aws_kms_key.main.key_id
}