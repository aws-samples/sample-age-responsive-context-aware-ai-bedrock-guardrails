#!/usr/bin/env python3
"""
Secure JWT Token Generator
Usage: python3 generate_jwt.py <user_id> [expires_in_hours]
"""

import jwt
import sys
import os
import secrets
import hashlib
from datetime import datetime, timedelta, timezone

def generate_secure_jwt_token(user_id, expires_in_hours=1):
    """Generate secure JWT token with proper claims"""
    
    # Get secret from environment or generate secure random one
    secret_key = os.environ.get('JWT_SECRET')
    if not secret_key:
        secret_key = secrets.token_urlsafe(64)
        print("⚠️  Generated random JWT secret. Set JWT_SECRET environment variable for production.")
    
    now = datetime.now(timezone.utc)
    payload = {
        'user_id': user_id,
        'iat': now,
        'exp': now + timedelta(hours=expires_in_hours),
        'nbf': now,  # Not before
        'iss': 'bedrock-guardrails-demo',  # Issuer
        'aud': 'demo-client',  # Audience
        'jti': secrets.token_hex(16),  # JWT ID for uniqueness
        'demo': True  # Mark as demo token
    }
    
    token = jwt.encode(payload, secret_key, algorithm='HS256')
    return token, secret_key

def verify_jwt_token(token, secret_key):
    """Verify and decode JWT token"""
    try:
        payload = jwt.decode(token, secret_key, algorithms=['HS256'])
        return payload
    except jwt.ExpiredSignatureError:
        raise ValueError("Token has expired")
    except jwt.InvalidTokenError:
        raise ValueError("Invalid token")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 generate_jwt.py <user_id> [expires_in_hours]")
        print("\nAvailable demo users:")
        print("  student-123   (Demo student)")
        print("  teacher-456   (Demo teacher)")
        print("  patient-789   (Demo patient)")
        print("  provider-101  (Demo provider)")
        print("\nExample: python3 generate_jwt.py student-123 1")
        sys.exit(1)
    
    user_id = sys.argv[1]
    expires_in_hours = int(sys.argv[2]) if len(sys.argv) > 2 else 1
    
    # Validate user ID
    if not user_id or len(user_id) < 3:
        print("❌ Invalid user ID. Must be at least 3 characters.")
        sys.exit(1)
    
    try:
        token, secret_key = generate_secure_jwt_token(user_id, expires_in_hours)
        
        print(f"✅ Generated secure JWT token for user '{user_id}':")
        print(f"Token: {token}")
        print(f"Expires in: {expires_in_hours} hour(s)")
        
        # Verify token works
        try:
            payload = verify_jwt_token(token, secret_key)
            print(f"\n✅ Token verification successful")
        except Exception as verify_error:
            print(f"\n⚠️  Token generated but verification failed: {verify_error}")
            print("   This may be due to clock skew or encoding issues.")
        
        print("\n🔒 Security features:")
        print("  - Secure random JWT ID")
        print("  - Short expiration time")
        print("  - Issuer and audience claims")
        print("  - Not-before claim")
        print("  - Demo flag for identification")
        
        print("\n⚠️  This is a demo token. Use proper OAuth/OIDC in production!")
        
    except Exception as e:
        print(f"❌ Error generating token: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()