# CloudWatch - Age-Responsive AI Module
# Logging and monitoring configuration

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda" {
  name              = "/aws/lambda/${local.name_prefix}-function-${local.suffix}"
  retention_in_days = var.cloudwatch_config.log_retention_days
  kms_key_id        = var.cloudwatch_config.enable_kms_encryption ? aws_kms_key.main.arn : null

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-lambda-logs"
    Purpose = "Lambda function logs"
  })
}

# CloudWatch Log Group for API Gateway (conditional)
resource "aws_cloudwatch_log_group" "api_gateway" {
  count             = var.cloudwatch_config.enable_kms_encryption ? 1 : 0
  name              = "/aws/apigateway/${local.name_prefix}-api-${local.suffix}"
  retention_in_days = var.cloudwatch_config.log_retention_days
  kms_key_id        = aws_kms_key.main.arn

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-api-gateway-logs"
    Purpose = "API Gateway access logs"
  })
}

# CloudWatch Metric Alarm for Lambda Errors
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  alarm_name          = "${local.name_prefix}-lambda-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This metric monitors lambda errors"
  alarm_actions       = []

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-lambda-error-alarm"
    Purpose = "Monitor Lambda function errors"
  })
}

# CloudWatch Metric Alarm for Lambda Duration
resource "aws_cloudwatch_metric_alarm" "lambda_duration" {
  alarm_name          = "${local.name_prefix}-lambda-duration"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "Duration"
  namespace           = "AWS/Lambda"
  period              = "300"
  statistic           = "Average"
  threshold           = "25000"  # 25 seconds (timeout is 30)
  alarm_description   = "This metric monitors lambda duration"
  alarm_actions       = []

  dimensions = {
    FunctionName = aws_lambda_function.main.function_name
  }

  tags = merge(local.common_tags, {
    Name    = "${local.name_prefix}-lambda-duration-alarm"
    Purpose = "Monitor Lambda function duration"
  })
}