#!/usr/bin/env python3
"""
JWT Token Generator for Production Testing
Usage: python3 generate_jwt.py <user_id>
"""

import jwt
import sys
from datetime import datetime, timedelta

def generate_jwt_token(user_id, secret_key="production-jwt-secret-key-change-in-production"):
    """Generate JWT token for testing"""
    
    payload = {
        'user_id': user_id,
        'iat': datetime.utcnow(),
        'exp': datetime.utcnow() + timedelta(hours=24)  # 24 hour expiry
    }
    
    token = jwt.encode(payload, secret_key, algorithm='HS256')
    return token

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 generate_jwt.py <user_id>")
        print("\nAvailable test users:")
        print("  student-123   (8th grade student)")
        print("  teacher-456   (Math teacher)")
        print("  patient-789   (Healthcare patient)")
        print("  provider-101  (Healthcare provider)")
        sys.exit(1)
    
    user_id = sys.argv[1]
    token = generate_jwt_token(user_id)
    
    print(f"JWT Token for user '{user_id}':")
    print(f"Bearer {token}")
    print("\nUse this in Authorization header:")
    print(f"Authorization: Bearer {token}")

if __name__ == "__main__":
    main()