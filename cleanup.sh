#!/bin/bash

# 🧹 Complete Cleanup Script for Age-Responsive AI Production System
# This script destroys all AWS resources and cleans up local files automatically

set -e  # Exit on any error

echo "🧹 Starting complete cleanup of Age-Responsive AI system..."
echo "⚠️  This will destroy ALL AWS resources and clean local files!"
echo ""

# Confirmation prompt
read -p "Are you sure you want to proceed? (yes/no): " confirm
if [[ $confirm != "yes" ]]; then
    echo "❌ Cleanup cancelled"
    exit 0
fi

echo ""
echo "🚀 Starting cleanup process..."

# 1. Stop web demo server if running
echo "🔌 Stopping web demo server..."
if lsof -ti:8000 >/dev/null 2>&1; then
    lsof -ti:8000 | xargs kill -9
    echo "✅ Web demo server stopped (port 8000)"
else
    echo "ℹ️  Web demo server not running"
fi

if lsof -ti:8080 >/dev/null 2>&1; then
    lsof -ti:8080 | xargs kill -9
    echo "✅ Web demo server stopped (port 8080)"
else
    echo "ℹ️  Web demo server not running on port 8080"
fi

# 2. Deactivate virtual environment if active
echo ""
echo "🐍 Deactivating virtual environment..."
if [[ "$VIRTUAL_ENV" != "" ]]; then
    deactivate 2>/dev/null || true
    echo "✅ Virtual environment deactivated"
else
    echo "ℹ️  No virtual environment active"
fi

# 3. Destroy AWS infrastructure
echo ""
echo "☁️  Destroying AWS infrastructure..."
cd terraform

if [ -f "terraform.tfstate" ] || [ -d ".terraform" ]; then
    echo "🔥 Running terraform destroy..."
    terraform destroy -auto-approve
    echo "✅ AWS resources destroyed"
else
    echo "ℹ️  No Terraform state found - nothing to destroy"
fi

# 4. Clean Terraform files
echo ""
echo "🗂️  Cleaning Terraform files..."
rm -rf .terraform*
rm -f terraform.tfstate*
rm -f .terraform.lock.hcl
echo "✅ Terraform files cleaned"

# 5. Clean Lambda build artifacts
echo ""
echo "📦 Cleaning Lambda build artifacts..."
cd ../lambda
rm -f app.zip
rm -rf package/
rm -f *.pyc
rm -rf __pycache__/
echo "✅ Lambda artifacts cleaned"

# 6. Clean utils artifacts
echo ""
echo "🔧 Cleaning utils artifacts..."
cd ../utils
rm -f *.pyc
rm -rf __pycache__/
echo "✅ Utils artifacts cleaned"

# 7. Remove virtual environment
echo ""
echo "🗑️  Removing virtual environment..."
cd ..
if [ -d "venv" ]; then
    rm -rf venv
    echo "✅ Virtual environment removed"
else
    echo "ℹ️  No virtual environment found"
fi

# 8. Clean web demo cache (optional)
echo ""
echo "🌐 Cleaning web demo cache..."
cd web-demo
# Clear any cached API endpoints from localStorage (user will need to do this manually in browser)
echo "ℹ️  Note: Clear browser localStorage manually if needed"
echo "   - Open browser console"
echo "   - Run: localStorage.clear()"

# 9. Summary
echo ""
echo "🎉 Cleanup completed successfully!"
echo ""
echo "📋 What was cleaned:"
echo "   ✅ AWS resources destroyed (Lambda, API Gateway, DynamoDB, etc.)"
echo "   ✅ Terraform state and cache files removed"
echo "   ✅ Lambda deployment packages removed"
echo "   ✅ Python cache files removed"
echo "   ✅ Virtual environment removed"
echo "   ✅ Web demo servers stopped"
echo ""
echo "💡 To redeploy later:"
echo "   1. Run: ./deploy.sh"
echo "   2. Follow QUICK_START.md instructions"
echo ""
echo "🧹 All done! Your system is now completely cleaned up."