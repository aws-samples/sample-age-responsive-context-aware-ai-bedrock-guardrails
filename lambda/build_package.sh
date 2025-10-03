#!/bin/bash

# Build Lambda deployment package with dependencies
echo "Building Lambda deployment package..."

# Clean up previous builds
rm -rf package/
rm -f app.zip

# Create package directory
mkdir -p package

# Install dependencies to package directory
pip install -r requirements.txt -t package/

# Copy Lambda function code
cp app.py package/

# Create deployment zip
cd package
zip -r ../app.zip .
cd ..

echo "Lambda package built: app.zip"