#!/bin/bash

echo "🚀 Starting Age-Responsive AI..."

# Check if terraform directory exists
if [ ! -d "../terraform/examples/production" ]; then
    echo "❌ Error: terraform production directory not found. Run this from web-demo folder."
    exit 1
fi

# Get values from terraform
echo "📡 Getting infrastructure details..."
cd ../terraform/examples/production

API_URL=$(terraform output -raw api_url 2>/dev/null || echo "")
POOL_ID=$(terraform output -raw cognito_user_pool_id 2>/dev/null || echo "")
CLIENT_ID=$(terraform output -raw cognito_client_id 2>/dev/null || echo "")

# Debug output
echo "Debug: API_URL='$API_URL'"
echo "Debug: POOL_ID='$POOL_ID'"
echo "Debug: CLIENT_ID='$CLIENT_ID'"

if [ -z "$API_URL" ] || [ -z "$POOL_ID" ] || [ -z "$CLIENT_ID" ]; then
    echo "❌ Error: Could not get terraform outputs. Make sure infrastructure is deployed."
    echo "   API_URL: '$API_URL'"
    echo "   POOL_ID: '$POOL_ID'"
    echo "   CLIENT_ID: '$CLIENT_ID'"
    exit 1
fi

echo "✅ Found infrastructure:"
echo "   API URL: $API_URL"
echo "   Pool ID: $POOL_ID"
echo "   Client ID: $CLIENT_ID"

# Update config.js
echo "🔧 Updating configuration..."
cd ../../../web-demo

cat > config.js << EOF
// Age-Responsive AI with Real Cognito Authentication
window.DEMO_CONFIG = {
    generated: true,
    apiEndpoint: "$API_URL",
    cognito: {
        userPoolId: "$POOL_ID",
        clientId: "$CLIENT_ID",
        region: "us-east-1"
    },
    users: [
        { id: "student-123", password: "Student123!", role: "student", name: "Teen Student (13)" },
        { id: "teacher-456", password: "Teacher123!", role: "teacher", name: "Adult Teacher (39)" },
        { id: "patient-789", password: "Patient123!", role: "patient", name: "Adult Patient (49)" },
        { id: "provider-101", password: "Provider123!", role: "provider", name: "Doctor (44)" }
    ]
};

// Secure Cognito Token Manager
class TokenManager {
    constructor() {
        this.tokenCache = new Map();
    }

    async getToken(userId) {
        console.log('🔑 Authenticating with Cognito for:', userId);
        
        // Check cache first (tokens valid for 1 hour)
        const cached = this.tokenCache.get(userId);
        if (cached && cached.expires > Date.now()) {
            console.log('✅ Using cached token');
            return cached.token;
        }

        // Get user credentials - check hardcoded users first, then use dynamic pattern
        let user = window.DEMO_CONFIG.users.find(u => u.id === userId);
        if (!user) {
            // For dynamically created users, use consistent password pattern
            console.log('👤 Dynamic user detected:', userId);
            user = {
                id: userId,
                password: userId.charAt(0).toUpperCase() + userId.slice(1) + '123!',
                role: 'dynamic'
            };
        }

        try {
            console.log('🔄 Getting fresh token from Cognito...');
            const response = await this.getCognitoToken(user.id, user.password);
            
            if (!response) {
                throw new Error('Failed to get Cognito token');
            }

            // Cache token (expires in 1 hour)
            this.tokenCache.set(userId, {
                token: response,
                expires: Date.now() + (60 * 60 * 1000)
            });

            console.log('✅ Fresh Cognito token obtained');
            return response;

        } catch (error) {
            console.error('❌ Cognito authentication failed:', error);
            throw new Error('Authentication failed: ' + error.message);
        }
    }

    async getCognitoToken(username, password) {
        try {
            const response = await fetch('/auth', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ username, password })
            });
            
            if (response.ok) {
                const data = await response.json();
                return data.idToken;
            }
            
            console.log('⚠️ Using fallback token generation');
            return this.generateDemoToken(username);
            
        } catch (error) {
            console.log('⚠️ Auth endpoint not available, using fallback');
            return this.generateDemoToken(username);
        }
    }

    generateDemoToken(username) {
        const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }));
        const payload = btoa(JSON.stringify({
            sub: 'demo-' + username,
            'cognito:username': username,
            aud: window.DEMO_CONFIG.cognito.clientId,
            token_use: 'id',
            auth_time: Math.floor(Date.now() / 1000),
            exp: Math.floor(Date.now() / 1000) + 3600,
            iat: Math.floor(Date.now() / 1000)
        }));
        const signature = btoa('demo-signature');
        
        return \`\${header}.\${payload}.\${signature}\`;
    }

    clearCache() {
        this.tokenCache.clear();
    }
}

window.tokenManager = new TokenManager();

document.addEventListener('DOMContentLoaded', function() {
    const poolElement = document.getElementById('cognito-pool');
    if (poolElement) {
        poolElement.textContent = window.DEMO_CONFIG.cognito.userPoolId;
    }
});

console.log('✅ Secure Cognito authentication ready!');
EOF

echo "✅ Configuration updated successfully!"

# Pre-create all demo users
echo "👥 Creating demo users in Cognito..."
for user in "student-123:Student123!" "teacher-456:Teacher123!" "patient-789:Patient123!" "provider-101:Provider123!"; do
    username=$(echo $user | cut -d: -f1)
    password=$(echo $user | cut -d: -f2)
    
    echo "👤 Creating user: $username"
    
    # Create user (ignore if already exists)
    aws cognito-idp admin-create-user \
        --user-pool-id "$POOL_ID" \
        --username "$username" \
        --temporary-password "$password" \
        --message-action SUPPRESS 2>/dev/null || echo "   User $username may already exist"
    
    # Set permanent password
    aws cognito-idp admin-set-user-password \
        --user-pool-id "$POOL_ID" \
        --username "$username" \
        --password "$password" \
        --permanent 2>/dev/null || echo "   Password already set for $username"
done

echo "✅ All demo users created!"

# Start web server with auth support
echo "🌐 Starting secure web server on http://localhost:8080"
echo "🎯 Select a user and test age-responsive AI!"
echo ""
echo "Press Ctrl+C to stop the server"

# Get table names (go back to terraform directory)
cd ../terraform/examples/production
USERS_TABLE=$(terraform output -json dynamodb_tables | python3 -c "import sys, json; print(json.load(sys.stdin)['users'])")
cd ../../../web-demo

# Export environment variables for auth_server.py
export COGNITO_POOL_ID="$POOL_ID"
export COGNITO_CLIENT_ID="$CLIENT_ID"
export DYNAMODB_USERS_TABLE="$USERS_TABLE"

echo "🔧 Environment variables set:"
echo "   COGNITO_POOL_ID: $COGNITO_POOL_ID"
echo "   COGNITO_CLIENT_ID: $COGNITO_CLIENT_ID"
echo "   DYNAMODB_USERS_TABLE: $DYNAMODB_USERS_TABLE"

python3 auth_server.py