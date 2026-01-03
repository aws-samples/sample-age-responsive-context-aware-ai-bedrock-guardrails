# Provider Configuration - Age-Responsive AI Production Example
# AWS provider with default tags

provider "aws" {
  region = var.region

  default_tags {
    tags = var.common_tags
  }
}