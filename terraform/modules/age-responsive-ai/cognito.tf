# Cognito User Pool - Age-Responsive AI Module
# Enterprise authentication with JWT tokens

# Cognito User Pool for authentication
resource "aws_cognito_user_pool" "main" {
  name = "responsive-ai-users"

  password_policy {
    minimum_length    = var.cognito_config.password_policy.minimum_length
    require_lowercase = var.cognito_config.password_policy.require_lowercase
    require_numbers   = var.cognito_config.password_policy.require_numbers
    require_symbols   = var.cognito_config.password_policy.require_symbols
    require_uppercase = var.cognito_config.password_policy.require_uppercase
  }

  auto_verified_attributes = length(var.cognito_config.auto_verified_attributes) > 0 ? var.cognito_config.auto_verified_attributes : null

  tags = merge(local.common_tags, {
    Name    = "ResponsiveAI-UserPool"
    Purpose = "User authentication for age-responsive AI"
  })

  lifecycle {
    ignore_changes = [schema]
  }
}

# Cognito User Pool Client
resource "aws_cognito_user_pool_client" "main" {
  name         = "responsive-ai-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false
  
  explicit_auth_flows = [
    "ADMIN_NO_SRP_AUTH",
    "USER_PASSWORD_AUTH"
  ]

  supported_identity_providers = ["COGNITO"]
  
  # Token validity settings
  id_token_validity = 60  # 1 hour
  access_token_validity = 60  # 1 hour
  refresh_token_validity = 30  # 30 days
  
  token_validity_units {
    id_token = "minutes"
    access_token = "minutes"
    refresh_token = "days"
  }
}