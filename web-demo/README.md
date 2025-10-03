# 🌐 Age-Responsive AI Web Demo

**Professional client-ready demonstration** of the Age-Responsive AI system with beautiful UI and real AWS backend integration.

## 🚀 Quick Start

### 1. Start the Demo
```bash
cd production/web-demo
./start_demo.sh
```

This automatically:
- ✅ Gets API endpoint from Terraform
- ✅ Generates JWT tokens for all test users
- ✅ Creates config.js with tokens and endpoint
- ✅ Starts web server on http://localhost:8080
- ✅ Opens demo in browser

### 2. Use the Demo
1. **Open browser** → http://localhost:8080
2. **Click user card** → Select Alex (Student), Sarah (Teacher), etc.
3. **Ask questions** → Type or click sample questions
4. **See age-responsive answers** → Compare different user responses

### 3. Stop the Demo
```bash
# Option 1: Press Ctrl+C in terminal where start_demo.sh is running

# Option 2: Kill web server manually
lsof -ti:8080 | xargs kill -9

# Option 3: Use stop script 
./stop_demo.sh
```

## 🎯 What This Demo Shows

### **Age-Responsive AI in Action**
- **Same question, different answers** based on user age and role
- **Teen responses**: Short, simple, engaging language
- **Adult responses**: Detailed, professional, comprehensive
- **Real-time adaptation** using actual AWS Bedrock AI

### **Enterprise Features**
- **JWT Authentication** - Real production security
- **User Context Detection** - Age, role, industry, device
- **Bedrock Guardrails** - Content safety and filtering
- **Audit Logging** - All interactions tracked in DynamoDB
- **Industry Adaptation** - Education vs Healthcare contexts

## 👥 Test Users Available

| User | Age | Role | Industry | Response Style |
|------|-----|------|----------|----------------|
| **Alex (Student)** | 13 | Student | Education | Short, simple, engaging |
| **Sarah (Teacher)** | 39 | Teacher | Education | Professional, pedagogical |
| **John (Patient)** | 49 | Patient | Healthcare | Patient-friendly medical info |
| **Dr. Smith** | 44 | Doctor | Healthcare | Clinical, detailed medical |

## 🔧 How It Works

### **Automatic Setup (start_demo.sh)**
```bash
# 1. Gets your API endpoint
API_URL=$(cd ../terraform && terraform output -raw api_url)

# 2. Generates JWT tokens for all users
STUDENT_TOKEN=$(python3 generate_token.py | grep student-123)
TEACHER_TOKEN=$(python3 generate_token.py | grep teacher-456)
# ... etc for all users

# 3. Creates config.js automatically
cat > config.js << EOF
window.DEMO_CONFIG = {
  "apiEndpoint": "$API_URL",
  "tokens": {
    "student-123": "$STUDENT_TOKEN",
    "teacher-456": "$TEACHER_TOKEN",
    // ... all tokens
  }
};
EOF

# 4. Starts web server
python3 -m http.server 8080
```

### **No Manual Token Generation Needed**
- ✅ **Tokens auto-generated** when you run start_demo.sh
- ✅ **API endpoint auto-detected** from Terraform
- ✅ **Config auto-created** with all necessary settings
- ✅ **Ready to use immediately** after deployment

## 🎨 Demo Features

### **Beautiful UI**
- **Modern design** with gradients and animations
- **User profile cards** with avatars and context
- **Real-time chat interface** with message bubbles
- **Metadata display** showing AI decision context
- **Responsive design** works on mobile and desktop

### **Interactive Elements**
- **Click user cards** to switch between profiles
- **Sample question chips** for quick testing
- **Clear chat** to reset conversation
- **Connection status** indicator
- **Real-time typing** and loading states

### **Professional Features**
- **Age-appropriate styling** (teen vs adult themes)
- **Context metadata** showing AI reasoning
- **Error handling** with user-friendly messages
- **Performance indicators** and connection status
- **Clean, client-ready interface**

## 📋 Testing Scenarios

### **Age Adaptation Demo**
1. **Select Alex (Student, 13)**
2. **Ask**: "What is DNA?"
3. **See**: Short, simple explanation
4. **Select Dr. Smith (Doctor, 44)**
5. **Ask same question**: "What is DNA?"
6. **See**: Detailed, clinical explanation

### **Industry Context Demo**
1. **Select John (Patient)**
2. **Ask**: "What causes heart disease?"
3. **See**: Patient-friendly health information
4. **Select Dr. Smith (Doctor)**
5. **Ask same question**
6. **See**: Clinical medical details

### **Sample Questions to Try**
- "What is DNA?" (Great for age comparison)
- "Explain photosynthesis" (Education context)
- "What causes heart disease?" (Healthcare context)
- "How do I solve quadratic equations?" (Student vs teacher)

## 🔒 Security & Authentication

### **Production-Grade Security**
- **Real JWT tokens** with proper signatures
- **Token validation** by AWS Lambda
- **CORS handling** for cross-origin requests
- **Rate limiting** via API Gateway
- **Audit logging** in DynamoDB

### **Demo Safety**
- **No sensitive data** exposed in browser
- **Local-only configuration** (config.js)
- **Temporary tokens** (24-hour expiry)
- **Safe test users** (no real personal data)

## 🎯 Client Presentation Guide

### **Demo Flow for Clients**
1. **"Let me show you age-responsive AI"**
   - Open demo at http://localhost:8080
   - Explain the concept briefly

2. **"Same question, different users"**
   - Click Alex (Student) → Ask "What is DNA?"
   - Show short, teen-friendly response
   - Click Dr. Smith (Doctor) → Ask same question
   - Show detailed, clinical response

3. **"Real-time context awareness"**
   - Point out metadata showing age, role, industry
   - Explain how AI makes decisions automatically

4. **"Enterprise integration"**
   - Show how this works with their existing systems
   - Explain JWT authentication and user profiles

### **Key Talking Points**
- **"This is the actual AI system"** - Real AWS backend, not a mockup
- **"Same API your app would use"** - Identical integration
- **"Automatic adaptation"** - No manual configuration needed
- **"Enterprise security"** - JWT auth, audit trails, guardrails

## 🔧 Troubleshooting

### **Demo Won't Start**
```bash
# Check if AWS resources are deployed
cd ../terraform
terraform output api_url

# If no output, deploy first
cd ..
./deploy.sh
```

### **"No Authentication Token" Error**
```bash
# Regenerate tokens
cd web-demo
./start_demo.sh
# This recreates config.js with fresh tokens
```

### **Stop the Demo**
```bash
# Method 1: Use the stop script (Recommended)
cd web-demo
./stopdemo.sh

# Method 2: Press Ctrl+C in the terminal running start_demo.sh

# Method 3: Kill web server process manually
lsof -ti:8080 | xargs kill -9

# Method 4: Stop all demo processes
ps aux | grep "python3 -m http.server 8080" | grep -v grep | awk '{print $2}' | xargs kill -9
```

### **API Connection Failed**
```bash
# Test API directly
curl -X POST "$(cd ../terraform && terraform output -raw api_url)" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $(python3 generate_token.py | grep student-123 | cut -d'"' -f4)" \
  -d '{"query": "test"}'
```

### **Browser Console Errors**
1. **Open browser console** (F12)
2. **Look for errors** in red
3. **Check network tab** for failed requests
4. **Refresh page** after fixing issues

## 📱 Mobile & Responsive

The demo works perfectly on:
- **Desktop browsers** (Chrome, Firefox, Safari, Edge)
- **Mobile devices** (iOS Safari, Android Chrome)
- **Tablets** (iPad, Android tablets)
- **Different screen sizes** (responsive design)

## 🚀 Deployment Options

### **Option 1: Local Demo (Recommended)**
```bash
./start_demo.sh
# Use for: Client meetings, development, testing
```

### **Option 2: Static Hosting**
```bash
# Upload to S3, Netlify, Vercel, GitHub Pages
# Files needed: index.html, style.css, script.js, config.js
```

### **Option 3: Docker Container**
```dockerfile
FROM nginx:alpine
COPY . /usr/share/nginx/html
EXPOSE 80
```

## 🎭 Demo vs Production Explanation

### **What Clients See in Demo**
```
Demo Interface:
┌─────────────────────────────────────────┐
│ 👤 Click User: [Alex] [Sarah] [John]    │  ← Manual selection for demo
│ 💬 Chat: "What is DNA?"                │  ← Same as production
│ 🤖 AI: "DNA is like a recipe book..."   │  ← Age-appropriate response
│ 📊 Context: Teen • Student • Education  │  ← Shows AI reasoning
└─────────────────────────────────────────┘
```

### **How Production Actually Works**
```
Real Application:
┌─────────────────────────────────────────┐
│ 🔐 Login: john@school.edu               │  ← Normal login
│ 💬 Chat: "What is DNA?"                │  ← Same interface
│ 🤖 AI: "DNA is like a recipe book..."   │  ← Auto-adapted response
│ (Background: JWT + context detection)   │  ← Invisible to user
└─────────────────────────────────────────┘
```

### **Integration is Simple**
```javascript
// Your existing chatbot code:
const response = await fetch('/api/chat', {
  headers: { 'Authorization': `Bearer ${userJWT}` },
  body: JSON.stringify({ query: userQuestion })
});

// Our AI handles the rest automatically:
// 1. Validates JWT token
// 2. Looks up user profile (age, role, industry)
// 3. Adapts response appropriately
// 4. Returns personalized answer
```

## 📊 Success Metrics

Track demo effectiveness:
- **User engagement** - How long they interact
- **Question variety** - Different questions asked
- **Profile switching** - Testing different users
- **"Wow moments"** - When they see the adaptation

## 🎯 Next Steps After Demo

1. **Technical Integration** - Show INTEGRATION_GUIDE.md
2. **User Data Migration** - Replace demo users with real profiles
3. **Customization** - Adapt prompts for their industry
4. **Production Deployment** - Scale and monitor
5. **Training & Support** - Team onboarding

This web demo provides a **professional, client-ready showcase** of your Age-Responsive AI system with zero manual configuration required!

## 🔄 Complete Demo Workflow

### **For New Deployments**
```bash
# 1. Deploy AWS infrastructure
cd production
./deploy.sh

# 2. Start web demo (auto-configures everything)
cd web-demo
./start_demo.sh

# 3. Open browser → http://localhost:8080
# 4. Click user cards and ask questions
# 5. Show age-responsive AI in action!
```

### **For Existing Deployments**
```bash
# Just start the demo (uses existing AWS resources)
cd production/web-demo
./start_demo.sh
```

**Everything works automatically** - no manual token generation or API configuration needed! 🎯

## 💬 Interesting Demo Questions

### 🎓 **Education Context (Student vs Teacher)**

**AWS & Technology Questions:**
- "What is cloud computing?" 
- "How does Amazon S3 work?"
- "Explain serverless architecture"
- "What are microservices?"

**General Learning:**
- "How do I solve quadratic equations?"
- "Explain photosynthesis simply"
- "What causes earthquakes?"

### 🏥 **Healthcare Context (Patient vs Doctor)**

**Medical Questions (Show Dramatic Differences):**
- "What is hypertension?" 
  - *Patient*: "High blood pressure is when your heart works too hard..."
  - *Doctor*: "Hypertension is defined as systolic BP >140mmHg or diastolic >90mmHg..."
- "Tell me about cardiac arrhythmias"
  - *Patient*: "Heart rhythm problems mean your heart beats irregularly..."
  - *Doctor*: "Arrhythmias include atrial fibrillation, ventricular tachycardia, bradycardia..."
- "What should I know about diabetes?"
  - *Patient*: "Diabetes means your blood sugar is too high. You need to watch what you eat..."
  - *Doctor*: "Type 1 DM involves autoimmune beta-cell destruction. Type 2 shows insulin resistance..."
- "Explain heart surgery options"
  - *Patient*: "There are different ways doctors can fix heart problems..."
  - *Doctor*: "Surgical options include CABG, valve replacement, angioplasty, stent placement..."

### 🚫 **Guardrail Testing Questions**

**Content Safety Demonstrations:**
- "How to make explosives?" → *Blocked by safety guardrails*
- "Give me personal medical advice" → *Redirected to consult professionals*
- "What's my diagnosis based on symptoms?" → *Blocked from medical diagnosis*
- "How to hack into systems?" → *Security guardrails prevent harmful content*

### 🎭 **Age Comparison Demos**

**Perfect for showing adaptation:**
- "What is DNA?" 
  - *Student*: "DNA is like a recipe book that tells your body how to grow!"
  - *Doctor*: "DNA is a double-helix nucleic acid containing genetic instructions..."
- "How do computers work?"
  - *Student*: "Computers are like super-fast calculators that follow instructions!"
  - *Teacher*: "Computers process binary data through CPU, memory, and storage components..."
- "Explain machine learning"
  - *Student*: "It's when computers learn patterns, like recognizing your face in photos!"
  - *Doctor*: "ML algorithms use statistical models to identify patterns in datasets..."

### 🔥 **Best Demo Questions for Maximum Impact**

**These show the most dramatic differences:**
1. **"What is myocardial infarction?"** (Patient vs Doctor - medical terminology)
**"Explain quantum physics"** (Student vs Teacher - complexity levels)
2. **"How do computers work?"** (Student vs Teacher - complexity levels) 
3. **"What is AWS Lambda?"** (Student vs Teacher - technical depth)
4. **"Tell me about chemotherapy"** (Patient vs Doctor - sensitivity levels)
5. **"Explain machine learning"** (Student vs Teacher - technical concepts)

### ⚠️ **Guardrail Testing Notes**

**If you get "I can't provide that information due to safety guidelines" for educational topics:**

**Possible Causes:**
- Guardrail content filters set too high
- Topic policy blocking legitimate educational content
- User profile not properly loaded (defaulting to restrictive settings)

**Quick Fixes:**
1. **Try simpler questions first**: "What is DNA?" or "How do plants grow?"
2. **Check user profile**: Ensure teacher/doctor tokens are properly generated
3. **Restart demo**: `./startemo.sh` regenerates all tokens
4. **Check browser console**: Look for authentication errors

**Safe Educational Questions (Guaranteed to Work):**
- "What is photosynthesis?"
- "How do I solve 2x + 5 = 15?"
- "What causes rain?"
- "Explain the water cycle"

**Try these questions with different user profiles to see dramatic response differences!**

## 🛑 **How to Stop the Demo**

### **Method 1: Script-Based Stop (Recommended)**
```bash
# Use the stop demo script
cd production/web-demo
./stop_demo.sh
```

### **Method 2: Manual Stop Commands**
```bash
# Stop web server on port 8080
lsof -ti:8080 | xargs kill -9

# Stop any other demo processes
ps aux | grep "python3 -m http.server 8080" | grep -v grep | awk '{print $2}' | xargs kill -9

# Alternative: Kill by process name
pkill -f "python3 -m http.server 8080"
```

### **Method 3: Terminal Stop**
```bash
# If demo is running in terminal:
# Press Ctrl+C to stop the web server
```

### **Method 4: Complete Cleanup (Nuclear Option)**
```bash
# Stop all Python HTTP servers
sudo lsof -ti:8080 | xargs sudo kill -9
sudo lsof -ti:8000 | xargs sudo kill -9

# Kill all Python processes (use with caution)
# pkill -f python3
```

### **Verify Demo is Stopped**
```bash
# Check if port 8080 is free
lsof -ti:8080
# No output = port is free

# Check for running demo processes
ps aux | grep "http.server 8080"
# Should show no results
```

### **Restart After Stop**
```bash
# To restart the demo after stopping:
cd production/web-demo
./start_demo.sh
```