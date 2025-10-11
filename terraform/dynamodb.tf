# DynamoDB Tables for Production

# Data sources
data "aws_caller_identity" "current" {}

# KMS Key for DynamoDB encryption
resource "aws_kms_key" "dynamodb_key" {
  description         = "KMS key for DynamoDB table encryption"
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
      }
    ]
  })
  
  tags = {
    Name        = "ResponsiveAI-DynamoDB-KMS"
    Environment = "production"
  }
}

resource "aws_kms_alias" "dynamodb_key_alias" {
  name          = "alias/dynamodb-encryption-key"
  target_key_id = aws_kms_key.dynamodb_key.key_id
}

# User Profiles Table
resource "aws_dynamodb_table" "users" {
  name           = "ResponsiveAI-Users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "ResponsiveAI-Users"
    Environment = "production"
  }
}

# Audit/Analytics Table
resource "aws_dynamodb_table" "audit" {
  name           = "ResponsiveAI-Audit"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "interaction_id"

  attribute {
    name = "interaction_id"
    type = "S"
  }

  attribute {
    name = "user_id"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "S"
  }

  global_secondary_index {
    name            = "UserIndex"
    hash_key        = "user_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Name        = "ResponsiveAI-Audit"
    Environment = "production"
  }
}

# Sample data for testing
resource "aws_dynamodb_table_item" "sample_student" {
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key

  item = jsonencode({
    user_id = {
      S = "student-123"
    }
    birth_date = {
      S = "2010-05-15"
    }
    role = {
      S = "student"
    }
    industry = {
      S = "education"
    }
    grade_level = {
      S = "8th"
    }
    parental_controls = {
      BOOL = true
    }
  })
}

resource "aws_dynamodb_table_item" "sample_teacher" {
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key

  item = jsonencode({
    user_id = {
      S = "teacher-456"
    }
    birth_date = {
      S = "1985-03-20"
    }
    role = {
      S = "teacher"
    }
    industry = {
      S = "education"
    }
    department = {
      S = "Mathematics"
    }
    parental_controls = {
      BOOL = false
    }
  })
}

resource "aws_dynamodb_table_item" "sample_patient" {
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key

  item = jsonencode({
    user_id = {
      S = "patient-789"
    }
    birth_date = {
      S = "1975-11-08"
    }
    role = {
      S = "patient"
    }
    industry = {
      S = "healthcare"
    }
    clearance_level = {
      S = "standard"
    }
    parental_controls = {
      BOOL = false
    }
  })
}

resource "aws_dynamodb_table_item" "sample_provider" {
  table_name = aws_dynamodb_table.users.name
  hash_key   = aws_dynamodb_table.users.hash_key

  item = jsonencode({
    user_id = {
      S = "provider-101"
    }
    birth_date = {
      S = "1980-07-12"
    }
    role = {
      S = "provider"
    }
    industry = {
      S = "healthcare"
    }
    department = {
      S = "Cardiology"
    }
    clearance_level = {
      S = "medical"
    }
    parental_controls = {
      BOOL = false
    }
  })
}