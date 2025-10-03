#!/bin/bash
echo "🚀 Starting Age-Responsive AI Demo"
echo ""

# Check if we're in the right directory
if [ ! -f "../terraform/main.tf" ]; then
    echo "❌ Error: Please run this from the web-demo directory"
    echo "   cd production/web-demo && ./start_demo.sh"
    exit 1
fi

# Get API endpoint from terraform
echo "🔧 Getting API endpoint from terraform..."
cd ../terraform
API_URL=$(terraform output -raw api_url 2>/dev/null)
if [ $? -ne 0 ] || [ -z "$API_URL" ]; then
    echo "❌ Error: Could not get API URL from terraform"
    echo "   Make sure terraform is deployed: cd terraform && terraform apply"
    exit 1
fi
echo "✅ API URL: $API_URL"
cd ../web-demo

# Activate virtual environment and generate JWT tokens
echo "🔑 Generating JWT tokens..."
if [ ! -d "../venv" ]; then
    echo "❌ Error: Virtual environment not found"
    echo "   Please run: cd .. && python3 -m venv venv && source venv/bin/activate && pip install PyJWT"
    exit 1
fi

source ../venv/bin/activate

# Generate tokens for all users
echo "Generating tokens for demo users..."
cd ../utils

# Generate tokens and extract them properly
STUDENT_TOKEN=$(python3 generate_jwt.py student-123 2>/dev/null | grep "Bearer " | cut -d' ' -f2 | tr -d '\n')
TEACHER_TOKEN=$(python3 generate_jwt.py teacher-456 2>/dev/null | grep "Bearer " | cut -d' ' -f2 | tr -d '\n')
PATIENT_TOKEN=$(python3 generate_jwt.py patient-789 2>/dev/null | grep "Bearer " | cut -d' ' -f2 | tr -d '\n')
PROVIDER_TOKEN=$(python3 generate_jwt.py provider-101 2>/dev/null | grep "Bearer " | cut -d' ' -f2 | tr -d '\n')

if [ -z "$STUDENT_TOKEN" ]; then
    echo "❌ Error: Could not generate JWT tokens"
    echo "   Make sure PyJWT is installed: pip install PyJWT"
    echo "   Testing token generation..."
    python3 generate_jwt.py student-123
    exit 1
fi

echo "✅ JWT tokens generated for all users"
echo "   Student: ${STUDENT_TOKEN:0:20}..."
echo "   Teacher: ${TEACHER_TOKEN:0:20}..."
echo "   Patient: ${PATIENT_TOKEN:0:20}..."
echo "   Provider: ${PROVIDER_TOKEN:0:20}..."
cd ../web-demo

# Create config.js with API endpoint and tokens
echo "📝 Creating config.js..."
cat > config.js << EOF
// Auto-generated config from terraform outputs
window.DEMO_CONFIG = {
  "apiEndpoint": "$API_URL",
  "tokens": {
    "student-123": "$STUDENT_TOKEN",
    "teacher-456": "$TEACHER_TOKEN",
    "patient-789": "$PATIENT_TOKEN",
    "provider-101": "$PROVIDER_TOKEN"
  },
  "generated": true
};
console.log('✅ Demo config loaded:', window.DEMO_CONFIG);
console.log('🔑 Available tokens:', Object.keys(window.DEMO_CONFIG.tokens));
EOF

echo "✅ Config.js created with API endpoint and JWT tokens"
echo "   API URL: $API_URL"
echo "   Tokens written to config.js"

# Start web server
echo "🌐 Starting web server on port 8080..."
python3 -m http.server 8080 &
SERVER_PID=$!

# Wait for server to start
sleep 2

echo ""
echo "🎉 Demo is ready!"
echo "📱 Open: http://localhost:8080"
echo ""
echo "🔧 If you get CORS errors, use Chrome with disabled security:"
echo "   /Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --disable-web-security --user-data-dir=/tmp/chrome_dev http://localhost:8080"
echo ""
echo "✨ Features:"
echo "   • API endpoint: Auto-loaded from terraform"
echo "   • JWT tokens: Auto-generated for all users"
echo "   • Real AI responses: Actual Bedrock API calls"
echo "   • Age filtering: Teen vs Adult responses"
echo "   • Role-based: Student/Teacher/Patient/Doctor"
echo "   • Guardrails: Content blocking active"
echo ""
echo "Press Ctrl+C to stop the demo"

# Wait for interrupt
trap "kill $SERVER_PID; exit" INT
wait $SERVER_PID



#### lsof -ti:8080,8081 | xargs kill -9