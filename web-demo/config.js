// Secure Demo Configuration - No hardcoded tokens
window.DEMO_CONFIG = {
    generated: true,
    apiEndpoint: "https://rr334o6yh2.execute-api.us-east-1.amazonaws.com/prod/ask",
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
        
        const demoToken = `${header}.${payload}.${signature}`;
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
