# API Gateway - Age-Responsive AI Module
# REST API with Cognito authentication

# API Gateway REST API
resource "aws_api_gateway_rest_api" "main" {
  name        = "${local.name_prefix}-api-${local.suffix}"
  description = "Age-Responsive AI API with Bedrock Guardrails"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-api"
    Purpose = "REST API for age-responsive AI"
  })
}

# Cognito Authorizer
resource "aws_api_gateway_authorizer" "cognito" {
  name            = "${local.name_prefix}-cognito-authorizer"
  rest_api_id     = aws_api_gateway_rest_api.main.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [aws_cognito_user_pool.main.arn]
  identity_source = "method.request.header.Authorization"
}

# API Gateway Resource
resource "aws_api_gateway_resource" "ask" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "ask"
}

# POST Method with Cognito Authorization
resource "aws_api_gateway_method" "ask_post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.ask.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id

  request_parameters = {
    "method.request.header.Authorization" = true
  }
}

# OPTIONS Method for CORS
resource "aws_api_gateway_method" "ask_options" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.ask.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# Lambda Integration
resource "aws_api_gateway_integration" "ask_post" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.ask.id
  http_method = aws_api_gateway_method.ask_post.http_method

  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.main.invoke_arn
}

# CORS Integration
resource "aws_api_gateway_integration" "ask_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.ask.id
  http_method = aws_api_gateway_method.ask_options.http_method

  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

# CORS Method Response
resource "aws_api_gateway_method_response" "ask_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.ask.id
  http_method = aws_api_gateway_method.ask_options.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# CORS Integration Response
resource "aws_api_gateway_integration_response" "ask_options" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.ask.id
  http_method = aws_api_gateway_method.ask_options.http_method
  status_code = aws_api_gateway_method_response.ask_options.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Requested-With'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [
    aws_api_gateway_integration.ask_options
  ]
}

# Lambda Permission
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.main.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_method.ask_post,
    aws_api_gateway_integration.ask_post,
    aws_api_gateway_method.ask_options,
    aws_api_gateway_integration.ask_options,
    aws_api_gateway_method_response.ask_options,
    aws_api_gateway_integration_response.ask_options,
    aws_api_gateway_authorizer.cognito
  ]

  rest_api_id = aws_api_gateway_rest_api.main.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_method.ask_post.id,
      aws_api_gateway_integration.ask_post.id,
      aws_api_gateway_authorizer.cognito.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.api_gateway_config.stage_name

  # CloudWatch logging
  dynamic "access_log_settings" {
    for_each = var.cloudwatch_config.enable_kms_encryption ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
      format = jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        caller         = "$context.identity.caller"
        user           = "$context.identity.user"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.responseLength"
      })
    }
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-api-stage"
    Purpose = "Production API stage"
  })
}