#!/bin/bash

# Responsive AI + Bedrock Guardrails Demo Deployment Script
# This script automates the complete deployment process

set -e

echo "🚀 Starting Responsive AI + Bedrock Guardrails Demo Deployment"
echo "=============================================================="

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed. Please install Terraform first."
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please install AWS CLI first."
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Please run 'aws configure' first."
    exit 1
fi

echo "✅ Prerequisites check passed"

# Get AWS region - default to us-east-1 for Bedrock support
AWS_REGION=$(aws configure get region || echo "us-east-1")
echo "🌍 Using AWS region: $AWS_REGION"
echo "ℹ️  Note: Bedrock is available in us-east-1, us-west-2, eu-west-1, ap-southeast-1, ap-northeast-1"

# Navigate to terraform directory
cd terraform

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init

# Plan deployment
echo "📋 Planning deployment..."
terraform plan -var="region=$AWS_REGION"

# Ask for confirmation
echo ""
read -p "🤔 Do you want to proceed with the deployment? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled"
    exit 1
fi

# Apply deployment
echo "🚀 Deploying infrastructure..."
if ! terraform apply -var="region=$AWS_REGION" -auto-approve; then
    echo "❌ Terraform deployment failed"
    exit 1
fi

# Get outputs
if ! API_URL=$(terraform output -raw api_url); then
    echo "❌ Failed to get API URL from Terraform output"
    exit 1
fi
echo ""
echo "✅ Deployment completed successfully!"
echo "============================================"
echo ""
echo "📝 Next Steps:"
echo "1. Test the production API with JWT tokens:"
echo "   API URL: $API_URL"
echo ""
echo "2. Use the professional web demo:"
echo "   cd web-demo && python3 -m http.server 8080"
echo "   Open: http://localhost:8080"
echo ""
echo "3. Generate JWT tokens for testing:"
echo "   cd utils && python3 generate_jwt.py student-123"
echo ""
echo "4. Try test queries with different user types:"
echo "   • student-123: 'Explain DNA' (teen-friendly)"
echo "   • provider-101: 'Explain DNA' (medical detail)"
echo ""

# No automatic web UI update needed - web-demo uses API configuration
echo "ℹ️  Web demo uses manual API configuration - no file updates needed"

echo ""
echo "🎉 Demo is ready!"
echo ""
echo "📊 Terraform outputs:"
terraform -chdir=../terraform output

echo ""
echo "🚀 Your production API is ready!"
echo "   Use web-demo/ for professional client presentations"
echo "   Use utils/generate_jwt.py for testing with different users"

echo ""
echo "🧹 To clean up everything later, run:"
echo "   ./cleanup.sh"
echo "   (Automatically: destroys AWS resources, stops web servers, cleans all files)"
echo ""
echo "🛑 To manually stop web server only:"
echo "   lsof -ti:8080 | xargs kill -9"