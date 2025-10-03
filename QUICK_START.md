# 🏭 Production-Ready Responsive AI with Bedrock Guardrails

## 📁 Repository Structure

```
production/
├── 📂 terraform/              # AWS Infrastructure as Code
│   ├── main.tf               # Core AWS resources (Lambda, API Gateway, DynamoDB)
│   ├── variables.tf          # Configuration variables
│   └── outputs.tf            # API endpoints and resource ARNs
├── 📂 lambda/                # Backend AI Logic
│   ├── app.py               # Main Lambda function with JWT auth
│   ├── requirements.txt     # Python dependencies (PyJWT, boto3)
│   └── build_package.sh     # Deployment package builder
├── 📂 utils/                 # Development Tools
│   └── generate_jwt.py      # JWT token generator for testing
├── 📂 web-demo/             # Interactive Web Demo
│   ├── index.html          # Demo interface
│   ├── style.css           # Modern UI styling
│   ├── script.js           # Frontend logic
│   └── startemo.sh         # Auto-setup demo script
├── 📄 deploy.sh             # One-command AWS deployment
├── 📄 cleanup.sh            # Complete cleanup script
├── 📄 QUICK_START.md        # This file - getting started guide
├── 📄 TESTING_GUIDE.md      # Comprehensive testing scenarios
└── 📄 INTEGRATION_GUIDE.md  # Production integration guide
```

### 🎯 Key Components
- **terraform/** - Deploys 15+ AWS resources automatically
- **lambda/app.py** - Core AI logic with age/role/industry adaptation
- **web-demo/** - Client-ready demo interface
- **utils/** - Development and testing tools

## Overview

This is the **production-ready version** with:
- ✅ **JWT Authentication** - Real user authentication
- ✅ **DynamoDB Integration** - User profiles and audit logging
- ✅ **Industry-Specific Prompts** - Education and Healthcare use cases
- ✅ **Automatic Context Detection** - No manual user input needed
- ✅ **Audit Logging** - Compliance and analytics
- ✅ **Security Best Practices** - Production-grade security

## Prerequisites

### 1. AWS Services Setup
```bash
# Enable required AWS services in your account:
# - Amazon Bedrock (Claude 3 Sonnet model access)
# - DynamoDB
# - Lambda
# - API Gateway
# - IAM
# - CloudWatch
```

### 2. Python Dependencies
```bash
# Create virtual environment (required on macOS)
python3 -m venv venv
source venv/bin/activate
pip install PyJWT boto3
```

### 3. AWS CLI Configuration
```bash
aws configure
# Set region to us-east-1 (Bedrock supported region)
```

## Deployment
cd production

### One-Command Deployment
```bash
./deploy.sh
```

This deploys:
- **15 AWS Resources** (Lambda, API Gateway, DynamoDB, etc.)
- **User Profile Database** with sample data
- **Audit Logging System**
- **JWT Authentication**
- **Industry-Specific AI Prompts**

## Industry Use Cases

### 🎓 Education Platform
**Sample Users:**
- `student-123` - 8th grade student with parental controls
- `teacher-456` - Math teacher

**Features:**
- Age-appropriate educational content
- Grade-level specific responses
- Parental control compliance
- Educational focus in all responses

### 🏥 Healthcare Platform  
**Sample Users:**
- `patient-789` - Adult patient
- `provider-101` - Healthcare provider (Cardiology)

**Features:**
- HIPAA-compliant responses
- Role-based medical information
- Patient vs provider appropriate content
- Medical ethics compliance

## Testing Production API

### 1. Generate JWT Token
```bash
# Activate virtual environment
cd /Users/kpradipp/Desktop/untitled\ folder\ 2/production
python3 -m venv venv
source venv/bin/activate

# Install PyJWT
pip install PyJWT

# Generate token for testing
cd utils
python3 generate_jwt.py student-123
```


### 2. Test with cURL
cd ../terraform
terraform output api_url
```bash
# Get your API URL from terraform output
API_URL=$(cd terraform && terraform output -raw api_url)

```bash
# Test with JWT token (replace <TOKEN> with actual token from step 1)
# Test with JWT token
curl -X POST $API_URL \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <JWT_TOKEN_FROM_STEP_1>" \
  -d '{"query": "Explain photosynthesis"}'
```
## Example command- 

curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{"query": "What is DNA?"}'
```

### 3. Expected Response
```json
{
  "response": "Photosynthesis is how plants make their own food using sunlight! Think of it like plants eating sunshine...",
  "metadata": {
    "user_id": "student-123",
    "role": "student", 
    "device": "desktop",
    "age": "teen",
    "industry": "education",
    "guardrail_applied": true,
    "timestamp": "2025-01-15T10:30:00"
  }
}
```

## Production Features

### 🔐 Authentication & Authorization
- **JWT Tokens** - Secure user authentication
- **User Profiles** - Stored in DynamoDB
- **Role-Based Access** - Different permissions per role

### 📊 User Context Detection
- **Age Calculation** - From birth date in profile
- **Role Detection** - From user database
- **Device Detection** - From User-Agent headers
- **Industry Context** - Education/Healthcare specific

### 🛡️ Security & Compliance
- **Bedrock Guardrails** - Content filtering
- **Audit Logging** - All interactions logged
- **Data Encryption** - KMS encrypted environment variables
- **HIPAA/COPPA Ready** - Compliance features built-in

### 📈 Analytics & Monitoring
- **Interaction Logging** - DynamoDB audit table
- **CloudWatch Metrics** - Performance monitoring
- **User Analytics** - Usage patterns and insights

## Sample Test Scenarios

### Education Use Case
```bash
# Generate student token
source venv/bin/activate
cd utils
python3 generate_jwt.py student-123

# Test educational query

curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{"query": "How do I solve quadratic equations?"}'

# Expected: Grade-appropriate math explanation
```

### Healthcare Use Case  
```bash
# Generate patient token
python3 generate_jwt.py patient-789

# Test health query
curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{"query": "What should I know about heart health?"}'

# Expected: Patient-appropriate health information
```

## Database Schema

### User Profiles Table
```json
{
  "user_id": "student-123",
  "birth_date": "2010-05-15", 
  "role": "student",
  "industry": "education",
  "grade_level": "8th",
  "parental_controls": true
}
```

### Audit Table
```json
{
  "interaction_id": "student-123-1642234567",
  "user_id": "student-123",
  "timestamp": "2025-01-15T10:30:00",
  "query": "How do plants grow?",
  "response_length": 245,
  "age_group": "teen",
  "role": "student",
  "industry": "education"
}
```

## Production Deployment Checklist

### Security
- [ ] Change JWT secret key in production
- [ ] Enable DynamoDB encryption at rest
- [ ] Set up VPC for Lambda (optional)
- [ ] Configure WAF for API Gateway
- [ ] Enable CloudTrail logging

### Monitoring
- [ ] Set up CloudWatch alarms
- [ ] Configure error notifications
- [ ] Set up cost monitoring
- [ ] Enable X-Ray tracing

### Compliance
- [ ] Review data retention policies
- [ ] Configure audit log retention
- [ ] Set up backup strategies
- [ ] Document security procedures

## Cost Estimation

**Monthly Production Costs:**
- Lambda: $10-50 (depends on usage)
- DynamoDB: $5-25 (pay-per-request)
- API Gateway: $3-15 (per million requests)
- Bedrock: $20-100 (depends on token usage)
- **Total: $38-190/month** for moderate usage

## Files Created

### Core Files
- `lambda/app.py` - Main Lambda function with JWT authentication
- `lambda/requirements.txt` - Python dependencies
- `lambda/build_package.sh` - Lambda deployment package builder
- `utils/generate_jwt.py` - JWT token generator for testing
- `terraform/` - Infrastructure as code (20+ AWS resources)

### Testing Files
- `TESTING_GUIDE.md` - Comprehensive testing scenarios
- `lambda/app.zip` - Built Lambda deployment package

## Cleanup

### Automated Cleanup (Recommended)
```bash
# One command to clean everything
./cleanup.sh
```

This script automatically:
- ✅ Destroys all AWS resources
- ✅ Stops web demo servers
- ✅ Deactivates virtual environment
- ✅ Removes all build artifacts
- ✅ Cleans Terraform state files
- ✅ Removes virtual environment

### Manual Cleanup (If Needed)
```bash
# Stop web servers
lsof -ti:8000 | xargs kill -9
lsof -ti:8080 | xargs kill -9

# Deactivate virtual environment
deactivate

# Destroy AWS resources
cd terraform
terraform destroy -auto-approve

# Clean local files
rm -rf .terraform*
rm -f terraform.tfstate*
cd ../lambda
rm -f app.zip
rm -rf package/
cd ..
rm -rf venv
```


## Support & Integration

### Integration Points
- **User Management System** - Replace sample data with real user API
- **Authentication Service** - Integrate with existing JWT provider  
- **Analytics Platform** - Connect audit logs to BI tools
- **Monitoring System** - Integrate with existing monitoring

### Custom Industries
To add new industries:
1. Add industry-specific prompt in `lambda/app.py`
2. Update user profile schema
3. Add sample data for testing
4. Update documentation

## Next Steps

1. **Deploy and Test** - Use sample users to verify functionality
2. **Integrate Authentication** - Connect to your user management system
3. **Customize Prompts** - Adapt for your specific industry needs
4. **Scale and Monitor** - Set up production monitoring and scaling
5. **Compliance Review** - Ensure meets your regulatory requirements

This production version demonstrates enterprise-ready AI with proper authentication, database integration, and industry-specific adaptations.