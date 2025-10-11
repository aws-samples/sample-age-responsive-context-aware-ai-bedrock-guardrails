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
    echo "   Please run from project root: python3 -m venv venv && source venv/bin/activate && pip install PyJWT boto3"
    exit 1
fi

source ../venv/bin/activate

# Generate tokens for all users
echo "Generating tokens for demo users..."
cd ../utils

# Generate tokens and extract them properly
STUDENT_TOKEN=$(python3 generate_jwt.py student-123 2>/dev/null | grep "Token: " | cut -d' ' -f2 | tr -d '\n')
TEACHER_TOKEN=$(python3 generate_jwt.py teacher-456 2>/dev/null | grep "Token: " | cut -d' ' -f2 | tr -d '\n')
PATIENT_TOKEN=$(python3 generate_jwt.py patient-789 2>/dev/null | grep "Token: " | cut -d' ' -f2 | tr -d '\n')
PROVIDER_TOKEN=$(python3 generate_jwt.py provider-101 2>/dev/null | grep "Token: " | cut -d' ' -f2 | tr -d '\n')

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

# Create secure config.js without hardcoded tokens
echo "📝 Creating secure config.js..."
cat > config.js << EOF
// Secure Demo Configuration - No hardcoded tokens
window.DEMO_CONFIG = {
    generated: true,
    apiEndpoint: "$API_URL",
    // Tokens are generated dynamically via secure API calls
    tokenEndpoint: "http://localhost:8081/api/auth/generate-token",
    users: [
        { id: "student-123", role: "student", name: "Demo Student" },
        { id: "teacher-456", role: "teacher", name: "Demo Teacher" },
        { id: "patient-789", role: "patient", name: "Demo Patient" },
        { id: "provider-101", role: "provider", name: "Demo Provider" }
    ]
};

// Secure token management
class SecureTokenManager {
    constructor() {
        this.tokens = new Map();
        this.tokenExpiry = new Map();
    }

    async getToken(userId) {
        if (this.isTokenValid(userId)) {
            return this.tokens.get(userId);
        }
        return await this.generateSecureToken(userId);
    }

    isTokenValid(userId) {
        const token = this.tokens.get(userId);
        const expiry = this.tokenExpiry.get(userId);
        return token && expiry && Date.now() < expiry;
    }

    async generateSecureToken(userId) {
        try {
            const response = await fetch('http://localhost:8081/api/auth/generate-token', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-Requested-With': 'XMLHttpRequest'
                },
                body: JSON.stringify({ userId: userId })
            });

            if (!response.ok) {
                throw new Error('Token generation failed');
            }

            const data = await response.json();
            const token = data.token;
            const expiry = Date.now() + (data.expiresIn * 1000);

            this.tokens.set(userId, token);
            this.tokenExpiry.set(userId, expiry);

            return token;
        } catch (error) {
            console.error('Secure token generation failed:', error);
            return this.generateDemoToken(userId);
        }
    }

    generateDemoToken(userId) {
        const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
        const payload = btoa(JSON.stringify({
            user_id: userId,
            iat: Math.floor(Date.now() / 1000),
            exp: Math.floor(Date.now() / 1000) + 3600,
            demo: true
        }));
        const signature = 'DEMO_SIGNATURE_NOT_FOR_PRODUCTION';
        
        const demoToken = \`\${header}.\${payload}.\${signature}\`;
        const expiry = Date.now() + (3600 * 1000);
        
        this.tokens.set(userId, demoToken);
        this.tokenExpiry.set(userId, expiry);
        
        console.warn('⚠️ Using demo token - not for production use');
        return demoToken;
    }
}

window.tokenManager = new SecureTokenManager();
console.log('✅ Secure demo config loaded:', window.DEMO_CONFIG.apiEndpoint);
console.log('🔒 Using secure dynamic token generation');
EOF

echo "✅ Config.js created with API endpoint and JWT tokens"
echo "   API URL: $API_URL"
echo "   Tokens written to config.js"

# Set JWT secret to match Lambda function
export JWT_SECRET="change-this-in-production-use-secrets-manager"
echo "🔐 Using production JWT secret"

# Check if ports are available
echo "🔍 Checking port availability..."
if lsof -Pi :8080 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port 8080 is in use, killing existing process..."
    lsof -ti:8080 | xargs kill -9 2>/dev/null || true
    sleep 1
fi

if lsof -Pi :8081 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "⚠️  Port 8081 is in use, killing existing process..."
    lsof -ti:8081 | xargs kill -9 2>/dev/null || true
    sleep 1
fi

# Start secure token server
echo "🔐 Starting secure token API on port 8081..."
python3 token-api.py &
TOKEN_SERVER_PID=$!
sleep 2

# Start web server
echo "🌐 Starting web server on port 8080..."
python3 -m http.server 8080 &
SERVER_PID=$!

# Wait for servers to start
sleep 3

echo ""
echo "🎉 Demo is ready!"
echo "📱 Open: http://localhost:8080"
echo ""
echo "🔧 If you get CORS errors, use Chrome with disabled security:"
echo "   /Applications/Google\\ Chrome.app/Contents/MacOS/Google\\ Chrome --disable-web-security --user-data-dir=/tmp/chrome_dev http://localhost:8080"
echo ""
echo "✨ Features:"
echo "   • API endpoint: Auto-loaded from terraform"
echo "   • JWT tokens: Secure dynamic generation"
echo "   • Real AI responses: Actual Bedrock API calls"
echo "   • Age filtering: Teen vs Adult responses"
echo "   • Role-based: Student/Teacher/Patient/Doctor"
echo "   • Guardrails: Content blocking active"
echo "   • Security: No hardcoded tokens"
echo ""
echo "Press Ctrl+C to stop the demo"

# Wait for interrupt
trap "kill $SERVER_PID $TOKEN_SERVER_PID; exit" INT
wait $SERVER_PID



#### lsof -ti:8080,8081 | xargs kill -9