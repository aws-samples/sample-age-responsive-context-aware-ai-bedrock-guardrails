#!/usr/bin/env python3
import json
import base64
from datetime import datetime, timedelta

def create_jwt_token(user_id, secret="production-jwt-secret-key-change-in-production"):
    """Create a simple JWT token without external dependencies"""
    
    # Header
    header = {
        "alg": "HS256",
        "typ": "JWT"
    }
    
    # Payload
    payload = {
        "user_id": user_id,
        "iat": int(datetime.utcnow().timestamp()),
        "exp": int((datetime.utcnow() + timedelta(hours=24)).timestamp())
    }
    
    # Encode header and payload
    header_b64 = base64.urlsafe_b64encode(json.dumps(header).encode()).decode().rstrip('=')
    payload_b64 = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode().rstrip('=')
    
    # Create signature (simplified - for demo only)
    import hmac
    import hashlib
    
    message = f"{header_b64}.{payload_b64}"
    signature = hmac.new(
        secret.encode(),
        message.encode(),
        hashlib.sha256
    ).digest()
    signature_b64 = base64.urlsafe_b64encode(signature).decode().rstrip('=')
    
    return f"{header_b64}.{payload_b64}.{signature_b64}"

# Generate tokens
tokens = {
    "student-123": create_jwt_token("student-123"),
    "teacher-456": create_jwt_token("teacher-456"),
    "patient-789": create_jwt_token("patient-789"),
    "provider-101": create_jwt_token("provider-101")
}

print(json.dumps(tokens, indent=2))