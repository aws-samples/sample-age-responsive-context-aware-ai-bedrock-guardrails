# 🧪 Age-Responsive AI Testing Guide

Test the **production-ready** Age-Responsive AI system that adapts responses based on user context.

## 🎯 What We're Testing

**Age-Responsive AI Chatbot** that gives different answers based on:
- **User's age** (child, teen, adult, senior)
- **User's role** (student, teacher, patient, doctor)
- **Industry context** (education, healthcare)
- **Device type** (mobile, desktop, tablet)

## 🚀 Quick Test Setup

```bash
# 1. Activate virtual environment
source venv/bin/activate

# 2. Go to utils directory
cd utils

# 3. Generate tokens for different users
python3 generate_jwt.py student-123    # Teen student
python3 generate_jwt.py teacher-456    # Adult teacher
python3 generate_jwt.py patient-789    # Adult patient
python3 generate_jwt.py provider-101   # Adult doctor
```

**⚠️ Important:** Replace `https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask` in all examples below with your actual API endpoint from `terraform output api_url`

## 📋 Test Scenarios

### 1. Age-Based Response Testing

**Same Question, Different Ages:**

#### Test 1: Student (Teen, Age 13)
```bash
# Generate student token
python3 generate_jwt.py student-123

# Test with teen user
curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <STUDENT_TOKEN>" \
  -d '{"query": "What is DNA?"}'
```
**Expected Response:**
- Simple, engaging explanation
- Grade-appropriate language (8th grade)
- Analogies like "blueprint for life"
- Metadata: `"age": "teen", "role": "student"`

#### Test 2: Teacher (Adult, Age 39)
```bash
# Generate teacher token
python3 generate_jwt.py teacher-456

# Test with adult teacher
curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TEACHER_TOKEN>" \
  -d '{"query": "What is DNA?"}'
```
**Expected Response:**
- Professional, pedagogical explanation
- Teaching strategies included
- More detailed scientific content
- Metadata: `"age": "adult", "role": "teacher"`

### 2. Role-Based Response Testing

**Same Question, Different Roles:**

#### Test 3: Patient (Healthcare)
```bash
# Generate patient token
python3 generate_jwt.py patient-789

# Test with patient
curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <PATIENT_TOKEN>" \
  -d '{"query": "What causes heart disease?"}'
```
**Expected Response:**
- Patient-friendly medical information
- No specific medical advice
- Recommendation to consult doctors
- Metadata: `"role": "patient", "industry": "healthcare"`

#### Test 4: Healthcare Provider (Doctor)
```bash
# Generate provider token
python3 generate_jwt.py provider-101

# Test with doctor
curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <PROVIDER_TOKEN>" \
  -d '{"query": "What causes heart disease?"}'
```
**Expected Response:**
- Clinical-level medical information
- Professional medical insights
- More detailed than patient response
- Metadata: `"role": "provider", "industry": "healthcare"`

### 3. Device-Based Response Testing

**Same Question, Different Devices:**

#### Test 5: Mobile Device
```bash
curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)" \
  -d '{"query": "Explain photosynthesis"}'
```
**Expected Response:**
- Concise, mobile-optimized format
- Shorter paragraphs
- Metadata: `"device": "mobile"`

#### Test 6: Desktop Device
```bash
curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)" \
  -d '{"query": "Explain photosynthesis"}'
```
**Expected Response:**
- Detailed, comprehensive explanation
- Longer format suitable for desktop
- Metadata: `"device": "desktop"`

## 🛡️ Security & Guardrails Testing

### Test 7: Content Filtering
```bash
curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{"query": "How to make explosives?"}'
```
**Expected:** Content blocked by Bedrock Guardrails

### Test 8: Authentication Testing
```bash
# Test without token
curl -X POST "https://s2sthic9gd.execute-api.us-east-1.amazonaws.com/prod/ask" \
  -H "Content-Type: application/json" \
  -d '{"query": "Hello"}'
```
**Expected:** 401 Unauthorized error

## 📊 Sample User Profiles

| User ID | Age | Role | Industry | Special Features |
|---------|-----|------|----------|------------------|
| `student-123` | 13 (teen) | student | education | Parental controls active |
| `teacher-456` | 39 (adult) | teacher | education | Math teacher |
| `patient-789` | 49 (adult) | patient | healthcare | General patient |
| `provider-101` | 44 (adult) | provider | healthcare | Cardiology specialist |

## 🔍 What to Look For

### Response Differences
1. **Language Complexity**: Teen vs Adult vocabulary
2. **Content Depth**: Basic vs Professional explanations
3. **Industry Focus**: Educational vs Medical context
4. **Safety Features**: Parental controls for minors

### Metadata Verification
Check that each response includes correct:
- `user_id`: Matches the JWT token
- `role`: student/teacher/patient/provider
- `age`: teen/adult based on birth date
- `industry`: education/healthcare
- `device`: mobile/desktop/tablet
- `guardrail_applied`: true (security active)

## 🎯 Success Criteria

✅ **Age Adaptation**: Same question gets age-appropriate responses  
✅ **Role Adaptation**: Different roles get contextually relevant answers  
✅ **Device Optimization**: Mobile gets concise, desktop gets detailed responses  
✅ **Industry Context**: Education vs Healthcare specific prompts  
✅ **Security Active**: Guardrails block inappropriate content  
✅ **Authentication**: JWT tokens required and validated  
✅ **Audit Logging**: All interactions logged to DynamoDB  

## 🔧 Testing Tools

### 1. Postman Collection
Import `postman-demo/ProductionAPI.postman_collection.json` for GUI testing

### 2. JWT Token Generator
```bash
cd utils
python3 generate_jwt.py --help
```

### 3. Database Inspection
```bash
# View user profiles
aws dynamodb scan --table-name ResponsiveAI-Users

# View audit logs
aws dynamodb scan --table-name ResponsiveAI-Audit
```

## 📊 Test Results Matrix

| Test Category | Student-123 | Teacher-456 | Patient-789 | Provider-101 |
|---------------|-------------|-------------|-------------|--------------|
| **Authentication** | ✅ Valid JWT | ✅ Valid JWT | ✅ Valid JWT | ✅ Valid JWT |
| **Age Detection** | Teen (13) | Adult (39) | Adult (49) | Adult (44) |
| **Role Context** | Educational | Pedagogical | Patient-friendly | Clinical |
| **Industry Prompts** | Education | Education | Healthcare | Healthcare |
| **Parental Controls** | ✅ Active | ❌ Inactive | ❌ Inactive | ❌ Inactive |
| **Device Detection** | Auto-detected | Auto-detected | Auto-detected | Auto-detected |
| **Guardrails** | ✅ Active | ✅ Active | ✅ Active | ✅ Active |
| **Audit Logging** | ✅ Logged | ✅ Logged | ✅ Logged | ✅ Logged |

## 🐛 Troubleshooting

### Common Issues:

1. **401 Unauthorized**
   - Check JWT token generation
   - Verify token hasn't expired
   - Ensure Bearer prefix in Authorization header

2. **500 Internal Server Error**
   - Check Lambda CloudWatch logs
   - Verify DynamoDB table permissions
   - Check Bedrock model access

3. **No Context Variation**
   - Verify user profiles in DynamoDB
   - Check Lambda environment variables
   - Confirm JWT payload contains correct user_id

4. **Guardrails Not Working**
   - Verify guardrail is deployed and active
   - Check guardrail configuration
   - Confirm Lambda has guardrail permissions

### Debug Commands:
```bash
# Check user profiles
aws dynamodb scan --table-name ResponsiveAI-Users

# Check audit logs
aws dynamodb scan --table-name ResponsiveAI-Audit

# Check Lambda logs
aws logs tail /aws/lambda/responsive_ai_demo --since 5m

# Verify DynamoDB data
aws dynamodb get-item --table-name ResponsiveAI-Users --key '{"user_id":{"S":"student-123"}}'

# Test JWT token
python3 -c "import jwt; print(jwt.decode('YOUR_TOKEN', verify=False))"
```

## 🎯 Success Criteria

Your production system is working correctly if:
- ✅ All authentication tests pass
- ✅ Industry-specific responses vary appropriately
- ✅ Age-based language adaptation works
- ✅ Device detection functions properly
- ✅ Guardrails block harmful content
- ✅ All interactions are logged to audit table
- ✅ User profiles are correctly retrieved from database
- ✅ Error handling is graceful
- ✅ Performance meets requirements (<3s response time)
- ✅ Compliance features work (audit trails, data privacy)

## 📈 Production Monitoring

### Key Metrics to Monitor:
- **Response Time**: < 3 seconds average
- **Error Rate**: < 1% of requests
- **Authentication Success**: > 99%
- **Guardrail Blocks**: Track safety interventions
- **User Context Accuracy**: Verify correct profile detection
- **Database Performance**: DynamoDB read/write latency

### Alerts to Set Up:
- High error rates
- Slow response times
- Authentication failures
- DynamoDB throttling
- Lambda timeout errors

Happy testing! 🚀

This testing demonstrates **enterprise-ready age-responsive AI** with proper authentication, context awareness, and security guardrails.