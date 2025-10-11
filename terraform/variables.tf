variable "region" {
  description = "AWS region for deployment (Bedrock available in: us-east-1, us-west-2, eu-west-1)"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "responsive-ai-demo"
}

variable "jwt_secret" {
  description = "JWT secret key for token validation"
  type        = string
  sensitive   = true
  default     = "change-this-in-production-use-secrets-manager"
}
