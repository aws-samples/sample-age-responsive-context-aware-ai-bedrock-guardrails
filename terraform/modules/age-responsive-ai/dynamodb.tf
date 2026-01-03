# DynamoDB Tables - Age-Responsive AI Module
# User profiles and audit logging with encryption

# User Profiles Table
resource "aws_dynamodb_table" "users" {
  name           = var.dynamodb_config.users_table_name != "" ? var.dynamodb_config.users_table_name : "ResponsiveAI-Users"
  billing_mode   = var.dynamodb_config.billing_mode
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  # Conditional encryption based on configuration
  dynamic "server_side_encryption" {
    for_each = var.kms_config.enable_kms_encryption ? [1] : []
    content {
      enabled     = true
      kms_key_arn = aws_kms_key.main.arn
    }
  }

  # Conditional point-in-time recovery
  dynamic "point_in_time_recovery" {
    for_each = var.dynamodb_config.point_in_time_recovery ? [1] : []
    content {
      enabled = true
    }
  }

  tags = merge(local.common_tags, {
    Name    = var.dynamodb_config.users_table_name != "" ? var.dynamodb_config.users_table_name : "ResponsiveAI-Users"
    Purpose = "User profiles and demographics"
  })
}

# Audit/Analytics Table
resource "aws_dynamodb_table" "audit" {
  name           = "${local.name_prefix}-audit-${local.suffix}"
  billing_mode   = var.dynamodb_config.billing_mode
  hash_key       = "interaction_id"

  attribute {
    name = "interaction_id"
    type = "S"
  }

  # TTL for automatic cleanup
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.main.arn
  }

  point_in_time_recovery {
    enabled = var.dynamodb_config.point_in_time_recovery
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-audit-table"
    Purpose = "Interaction audit and compliance logging"
  })
}