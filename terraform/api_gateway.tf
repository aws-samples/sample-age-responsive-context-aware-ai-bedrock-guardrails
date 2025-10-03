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
}