import os
import json
import html
import logging
import jwt
from datetime import datetime
from boto3 import client
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

bedrock = client('bedrock-runtime')
dynamodb = client('dynamodb')

def lambda_handler(event, context):
    """Production Lambda with automatic context detection"""
    
    # Handle CORS preflight requests
    if event.get('httpMethod') == 'OPTIONS' or event.get('requestContext', {}).get('http', {}).get('method') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization',
                'Access-Control-Max-Age': '86400'
            },
            'body': ''
        }
    
    try:
        # Extract user context from authentication and headers
        user_context = extract_user_context(event)
        
        # Create industry-specific prompt
        system_prompt = create_industry_prompt(
            user_context['role'],
            user_context['device'], 
            user_context['age'],
            user_context.get('industry', 'general'),
            user_context.get('additional_context', {})
        )
        
        # Prepare Claude 3 request body with age-appropriate token limits
        max_tokens = 50 if user_context['age'] == 'teen' else 100 if user_context['age'] == 'child' else 200
        
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": max_tokens,
            "temperature": 0.5,
            "system": system_prompt,
            "messages": [
                {
                    "role": "user",
                    "content": user_context['query']
                }
            ]
        }
        
        # Invoke Bedrock with Guardrails
        guardrail_id = os.environ.get('GUARDRAIL_ID')
        invoke_params = {
            'modelId': 'anthropic.claude-3-sonnet-20240229-v1:0',
            'body': json.dumps(request_body),
            'contentType': 'application/json',
            'accept': 'application/json'
        }
        
        if guardrail_id:
            invoke_params['guardrailIdentifier'] = guardrail_id
            invoke_params['guardrailVersion'] = 'DRAFT'
            
        response = bedrock.invoke_model(**invoke_params)
        
        # Parse response
        response_body = json.loads(response['body'].read())
        text = response_body['content'][0]['text']
        
        # Log interaction for audit
        log_interaction(user_context, text)
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type, Authorization'
            },
            'body': json.dumps({
                'response': text,
                'metadata': {
                    'user_id': user_context['user_id'],
                    'role': user_context['role'],
                    'device': user_context['device'],
                    'age': user_context['age'],
                    'industry': user_context.get('industry', 'general'),
                    'guardrail_applied': bool(guardrail_id),
                    'timestamp': datetime.now().isoformat()
                }
            })
        }
        
    except jwt.InvalidTokenError:
        return {
            'statusCode': 401,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Invalid or missing authentication token'})
        }
    except ClientError as e:
        error_code = e.response['Error']['Code']
        if error_code == 'ValidationException' and 'guardrail' in str(e):
            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                },
                'body': json.dumps({
                    'response': 'I can\'t provide that information due to safety guidelines. Please try a different question.',
                    'blocked': True,
                    'metadata': {
                        'guardrail_triggered': True,
                        'timestamp': datetime.now().isoformat()
                    }
                })
            }
        raise e
    except Exception as e:
        logger.error(f"Lambda execution error: {type(e).__name__}: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': 'Internal server error'})
        }

def extract_user_context(event):
    """Extract user context from JWT token and headers"""
    
    # 1. Extract and verify JWT token
    headers = event.get('headers', {})
    logger.info(f"All headers: {list(headers.keys())}")
    
    # API Gateway v2 may normalize headers differently
    auth_header = (
        headers.get('Authorization') or 
        headers.get('authorization') or 
        headers.get('AUTHORIZATION') or ''
    )
    logger.info(f"Auth header: {auth_header[:50]}...")
    
    if not auth_header.startswith('Bearer '):
        logger.error("Missing Bearer token")
        raise jwt.InvalidTokenError("Missing Bearer token")
    
    token = auth_header.replace('Bearer ', '')
    logger.info(f"Token extracted: {token[:50]}...")
    
    # Decode JWT with proper signature verification
    jwt_secret = os.environ.get('JWT_SECRET', 'demo-secret-key')
    logger.info(f"Using JWT secret: {jwt_secret[:20]}...")
    
    try:
        user_claims = jwt.decode(
            token, 
            jwt_secret, 
            algorithms=['HS256'], 
            audience='demo-client',  # Verify expected audience
            issuer='bedrock-guardrails-demo',  # Verify expected issuer
            options={"verify_signature": True, "verify_aud": True, "verify_iss": True}
        )
        logger.info(f"JWT decoded successfully: {user_claims}")
    except jwt.ExpiredSignatureError:
        logger.warning("JWT token has expired")
        raise jwt.InvalidTokenError("Token has expired")
    except jwt.InvalidSignatureError:
        logger.warning("JWT signature verification failed")
        raise jwt.InvalidTokenError("Invalid token signature")
    except Exception as e:
        logger.warning(f"JWT decode error: {type(e).__name__}: {str(e)}")
        raise jwt.InvalidTokenError(f"Token validation failed: {str(e)}")
    
    # 2. Get user profile from database
    user_profile = get_user_profile(user_claims['user_id'])
    
    # 3. Calculate age group from birth date
    age_group = calculate_age_group(user_profile.get('birth_date'))
    
    # 4. Detect device from User-Agent
    user_agent = event.get('headers', {}).get('User-Agent', '')
    device = detect_device_type(user_agent)
    
    # 5. Extract query from body
    body = json.loads(event.get('body', '{}'))
    query = body.get('query', '')
    
    return {
        'user_id': user_claims['user_id'],
        'age': age_group,
        'role': user_profile.get('role', 'guest'),
        'device': device,
        'query': query,
        'industry': user_profile.get('industry', 'general'),
        'additional_context': {
            'grade_level': user_profile.get('grade_level'),
            'department': user_profile.get('department'),
            'clearance_level': user_profile.get('clearance_level'),
            'parental_controls': user_profile.get('parental_controls', False)
        }
    }

def get_user_profile(user_id):
    """Get user profile from DynamoDB"""
    table_name = os.environ.get('USER_TABLE', 'ResponsiveAI-Users')
    
    try:
        response = dynamodb.get_item(
            TableName=table_name,
            Key={'user_id': {'S': user_id}}
        )
        
        if 'Item' in response:
            # Convert DynamoDB format to Python dict
            item = response['Item']
            return {
                'birth_date': item.get('birth_date', {}).get('S'),
                'role': item.get('role', {}).get('S', 'guest'),
                'industry': item.get('industry', {}).get('S', 'general'),
                'grade_level': item.get('grade_level', {}).get('S'),
                'department': item.get('department', {}).get('S'),
                'clearance_level': item.get('clearance_level', {}).get('S'),
                'parental_controls': item.get('parental_controls', {}).get('BOOL', False)
            }
    except Exception as e:
        logger.warning(f"Failed to get user profile: {e}")
    
    # Return demo profile based on user_id if database lookup fails
    demo_profiles = {
        'student-123': {'role': 'student', 'industry': 'education', 'birth_date': '2010-05-15'},
        'teacher-456': {'role': 'teacher', 'industry': 'education', 'birth_date': '1985-03-20'},
        'patient-789': {'role': 'patient', 'industry': 'healthcare', 'birth_date': '1975-11-08'},
        'provider-101': {'role': 'provider', 'industry': 'healthcare', 'birth_date': '1980-07-12'}
    }
    return demo_profiles.get(user_id, {'role': 'guest', 'industry': 'general'})

def calculate_age_group(birth_date):
    """Calculate age group from birth date"""
    if not birth_date:
        return 'adult'
    
    try:
        birth = datetime.fromisoformat(birth_date)
        age = (datetime.now() - birth).days // 365
        
        if age < 13:
            return 'child'
        elif age < 18:
            return 'teen'
        elif age < 65:
            return 'adult'
        else:
            return 'senior'
    except:
        return 'adult'

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

def create_industry_prompt(role, device, age, industry, additional_context):
    """Create industry-specific prompts"""
    
    # Base age-appropriate language
    age_styles = {
        'child': 'Use simple, fun language. Keep explanations very short (1-2 sentences max).',
        'teen': 'Keep responses very short and simple. Use casual language. Maximum 2-3 sentences only.',
        'adult': 'Provide comprehensive, professional responses.',
        'senior': 'Use clear, patient explanations. Avoid technical jargon.'
    }
    
    # Industry-specific contexts
    if industry == 'education':
        return create_education_prompt(role, device, age, additional_context, age_styles)
    elif industry == 'healthcare':
        return create_healthcare_prompt(role, device, age, additional_context, age_styles)
    else:
        return create_general_prompt(role, device, age, age_styles)

def create_education_prompt(role, device, age, context, age_styles):
    """Education industry specific prompt"""
    
    role_contexts = {
        'student': f"Educational content appropriate for grade {context.get('grade_level', 'unknown')}",
        'teacher': 'Professional educator providing comprehensive explanations',
        'parent': 'Family-friendly educational guidance',
        'administrator': 'Educational policy and administrative insights'
    }
    
    parental_note = " IMPORTANT: Parental controls active - keep content family-safe." if context.get('parental_controls') else ""
    
    # Teachers get full professional responses regardless of age context
    if role == 'teacher':
        return f"""
You are an AI assistant for professional educators.

User Context:
- Role: Professional Teacher/Educator
- Device: {device}
- Subject Area: {context.get('grade_level', 'General Education')}

Response Guidelines:
- Provide comprehensive, professional educational explanations
- Include pedagogical insights and teaching strategies when relevant
- Use appropriate academic terminology
- Focus on educational value and learning outcomes
- Maintain professional educator standards{parental_note}

You are helping a qualified educator - provide detailed, professional responses.
"""
    
    # Special handling for students (teens)
    if role == 'student' and age == 'teen':
        return f"""
You are an AI assistant for students. Keep responses VERY SHORT and simple.

User: {role} (age 13)
Device: {device}

IMPORTANT RULES:
- Maximum 2-3 sentences only
- Use simple, casual language like talking to a friend
- No bullet points or long lists
- Give just the basic answer they need
- Think like explaining to a middle school student

Example: "What is DNA?" → "DNA is like a recipe book that tells your body how to grow and what you'll look like!"
"""
    
    return f"""
You are an AI assistant for an educational platform.

User Context:
- Role: {role} ({role_contexts.get(role, 'General user')})
- Age Group: {age}
- Device: {device}
- Grade Level: {context.get('grade_level', 'Not specified')}

Response Guidelines:
- Language Style: {age_styles.get(age, age_styles['adult'])}
- Educational Focus: Provide learning-oriented responses with examples
- Safety: Always maintain educational appropriateness{parental_note}
- Device Format: Optimize for {device} viewing

Always prioritize educational value and age-appropriate content.
"""

def create_healthcare_prompt(role, device, age, context, age_styles):
    """Healthcare industry specific prompt"""
    
    role_contexts = {
        'patient': 'Patient-friendly medical information',
        'provider': 'Clinical insights and medical guidance',
        'nurse': 'Nursing-focused care information',
        'administrator': 'Healthcare administration and policy'
    }
    
    return f"""
You are an AI assistant for a healthcare platform.

User Context:
- Role: {role} ({role_contexts.get(role, 'General user')})
- Age Group: {age}
- Device: {device}
- Clearance: {context.get('clearance_level', 'Standard')}

Response Guidelines:
- Language Style: {age_styles.get(age, age_styles['adult'])}
- Medical Focus: Provide health-appropriate information
- Compliance: Follow HIPAA guidelines and medical ethics
- Safety: Never provide specific medical diagnoses or treatment advice
- Device Format: Optimize for {device} viewing

IMPORTANT: Always recommend consulting healthcare professionals for medical decisions.
"""

def create_general_prompt(role, device, age, age_styles):
    """General purpose prompt"""
    
    return f"""
You are a helpful AI assistant providing context-aware responses.

User Context:
- Role: {role}
- Age Group: {age}
- Device: {device}

Response Guidelines:
- Language Style: {age_styles.get(age, age_styles['adult'])}
- Device Format: Optimize for {device} viewing
- Safety: Maintain appropriate content for all users

Always be helpful, accurate, and appropriate for the user's context.
"""

def log_interaction(user_context, response):
    """Log interaction for audit and analytics"""
    log_table = os.environ.get('AUDIT_TABLE', 'ResponsiveAI-Audit')
    
    try:
        dynamodb.put_item(
            TableName=log_table,
            Item={
                'interaction_id': {'S': f"{user_context['user_id']}-{int(datetime.now().timestamp())}"},
                'user_id': {'S': user_context['user_id']},
                'timestamp': {'S': datetime.now().isoformat()},
                'query': {'S': user_context['query'][:500]},  # Truncate for storage
                'response_length': {'N': str(len(response))},
                'age_group': {'S': user_context['age']},
                'role': {'S': user_context['role']},
                'device': {'S': user_context['device']},
                'industry': {'S': user_context.get('industry', 'general')}
            }
        )
    except Exception as e:
        logger.warning(f"Failed to log interaction: {e}")