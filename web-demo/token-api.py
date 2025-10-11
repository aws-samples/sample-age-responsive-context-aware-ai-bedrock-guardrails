#!/usr/bin/env python3
"""
Secure Token API for Demo
Provides secure JWT token generation endpoint
"""

import jwt
import json
import secrets
import os
from datetime import datetime, timedelta
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse, parse_qs

class SecureTokenHandler(BaseHTTPRequestHandler):
    
    def __init__(self, *args, **kwargs):
        # Get secure JWT secret from environment
        self.jwt_secret = os.environ.get('JWT_SECRET', secrets.token_urlsafe(64))
        super().__init__(*args, **kwargs)
    
    def do_OPTIONS(self):
        """Handle CORS preflight requests"""
        self.send_response(200)
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, X-Requested-With')
        self.end_headers()
    
    def do_POST(self):
        """Handle token generation requests"""
        try:
            # Parse request
            if self.path == '/api/auth/generate-token':
                self.handle_token_generation()
            else:
                self.send_error(404, "Endpoint not found")
        except Exception as e:
            self.send_error(500, f"Server error: {str(e)}")
    
    def handle_token_generation(self):
        """Generate secure JWT token"""
        try:
            # Read request body
            content_length = int(self.headers.get('Content-Length', 0))
            post_data = self.rfile.read(content_length)
            request_data = json.loads(post_data.decode('utf-8'))
            
            user_id = request_data.get('userId')
            if not user_id:
                self.send_error(400, "userId is required")
                return
            
            # Validate user ID
            valid_users = ['student-123', 'teacher-456', 'patient-789', 'provider-101']
            if user_id not in valid_users:
                self.send_error(400, "Invalid userId")
                return
            
            # Generate secure token
            token = self.generate_secure_token(user_id)
            
            # Send response
            response = {
                'token': token,
                'expiresIn': 3600,  # 1 hour
                'userId': user_id,
                'generated': datetime.utcnow().isoformat(),
                'demo': True
            }
            
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.send_header('Access-Control-Allow-Origin', '*')
            self.end_headers()
            self.wfile.write(json.dumps(response).encode('utf-8'))
            
        except json.JSONDecodeError:
            self.send_error(400, "Invalid JSON")
        except Exception as e:
            self.send_error(500, f"Token generation failed: {str(e)}")
    
    def generate_secure_token(self, user_id):
        """Generate secure JWT token with proper claims"""
        now = datetime.utcnow()
        payload = {
            'user_id': user_id,
            'iat': now,
            'exp': now + timedelta(hours=1),
            'nbf': now,
            'iss': 'bedrock-guardrails-demo',
            'aud': 'demo-client',
            'jti': secrets.token_hex(16),
            'demo': True,
            'secure': True
        }
        
        return jwt.encode(payload, self.jwt_secret, algorithm='HS256')
    
    def log_message(self, format, *args):
        """Override to reduce log noise"""
        if self.path.startswith('/api/'):
            print(f"[{datetime.now().strftime('%H:%M:%S')}] {format % args}")

def run_token_server(port=8081):
    """Run the secure token server"""
    server_address = ('', port)
    httpd = HTTPServer(server_address, SecureTokenHandler)
    
    print(f"🔐 Secure Token API running on http://localhost:{port}")
    print("📋 Available endpoints:")
    print("  POST /api/auth/generate-token")
    print("🔑 JWT Secret:", "Environment" if os.environ.get('JWT_SECRET') else "Generated")
    print("⚠️  This is a demo server - use proper OAuth/OIDC in production!")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n🛑 Token server stopped")
        httpd.server_close()

if __name__ == '__main__':
    run_token_server()