import os
import json
import jwt
from datetime import datetime
from boto3 import client

def lambda_handler(event, context):
    """Production-ready context detection"""
    
    # Extract user context from real systems
    user_context = extract_user_context(event)
    
    # Create AI prompt with detected context
    system_prompt = create_responsive_prompt(
        user_context['role'],
        user_context['device'], 
        user_context['age']
    )
    
    # Process with Bedrock...
    return process_ai_request(system_prompt, user_context['query'])

def extract_user_context(event):
    """Extract context from real backend systems"""
    
    # 1. Get user from JWT token
    auth_token = event['headers'].get('Authorization', '').replace('Bearer ', '')
    jwt_secret = os.environ.get('JWT_SECRET', 'demo-secret-key')
    user_claims = jwt.decode(auth_token, jwt_secret, algorithms=['HS256'])
    
    # 2. Age detection from user profile
    birth_date = get_user_birth_date(user_claims['user_id'])
    age_group = calculate_age_group(birth_date)
    
    # 3. Role from authentication system
    role = user_claims.get('role', 'guest')
    
    # 4. Device detection from headers
    user_agent = event['headers'].get('User-Agent', '')
    device = detect_device_type(user_agent)
    
    # 5. Query from request body
    body = json.loads(event['body'])
    query = body.get('query', '')
    
    return {
        'age': age_group,
        'role': role,
        'device': device,
        'query': query,
        'user_id': user_claims['user_id']
    }

def calculate_age_group(birth_date):
    """Calculate age group from birth date"""
    if not birth_date:
        return 'adult'
    
    age = (datetime.now() - datetime.fromisoformat(birth_date)).days // 365
    
    if age < 13:
        return 'child'
    elif age < 18:
        return 'teen'
    elif age < 65:
        return 'adult'
    else:
        return 'senior'

def detect_device_type(user_agent):
    """Detect device from User-Agent header"""
    user_agent = user_agent.lower()
    
    if 'mobile' in user_agent or 'android' in user_agent:
        return 'mobile'
    elif 'tablet' in user_agent or 'ipad' in user_agent:
        return 'tablet'
    elif 'kiosk' in user_agent:
        return 'kiosk'
    else:
        return 'desktop'

def get_user_birth_date(user_id):
    """Get user birth date from database/user service"""
    # In production: call user service API or database
    # return user_service.get_user(user_id).birth_date
    return "1990-01-01"  # Demo placeholder

# Industry-specific context detection examples:

def healthcare_context(user_id):
    """Healthcare-specific context"""
    patient = get_patient_record(user_id)
    return {
        'age': calculate_age_group(patient.birth_date),
        'role': 'patient' if patient.is_patient() else 'provider',
        'medical_restrictions': patient.content_restrictions,
        'language_preference': patient.preferred_language
    }

def education_context(user_id):
    """Education platform context"""
    user = get_student_record(user_id)
    return {
        'age': calculate_age_group(user.birth_date),
        'role': user.role,  # student, teacher, parent
        'grade_level': user.grade_level,
        'parental_controls': user.parental_restrictions
    }

def enterprise_context(employee_id):
    """Enterprise application context"""
    employee = get_employee_from_ldap(employee_id)
    return {
        'age': 'adult',  # Workplace assumption
        'role': employee.job_role,
        'department': employee.department,
        'security_clearance': employee.clearance_level
    }