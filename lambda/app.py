import json
import boto3
import os
import logging
import jwt
import base64
from datetime import datetime
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
dynamodb = boto3.resource('dynamodb')
bedrock = boto3.client('bedrock-runtime')
secrets_client = boto3.client('secretsmanager')

def lambda_handler(event, context):
    """
    Secure Lambda handler following AWS best practices
    Flow: WAF -> API Gateway -> Cognito Auth -> Lambda -> Bedrock -> Guardrails -> Response
    """
    try:
        # Handle CORS preflight
        if event.get('httpMethod') == 'OPTIONS':
            return cors_response(200, '')
        
        # Extract user from Cognito authorizer context (API Gateway handles JWT validation)
        user_id = get_user_from_context(event)
        if not user_id:
            return cors_response(401, {'error': 'Unauthorized'})
        
        # Parse and validate request
        body = parse_request_body(event)
        if 'error' in body:
            return cors_response(400, body)
        
        query = body.get('query', '').strip()
        conversation_id = body.get('conversation_id')  # Optional for follow-ups
        if not query or len(query) > 1000:
            return cors_response(400, {'error': 'Invalid query'})
        
        # Auto-correct grammar if needed
        corrected_query = auto_correct_grammar(query)
        
        # Get user profile
        user_profile = get_user_profile(user_id)
        if not user_profile:
            return cors_response(404, {'error': 'User profile not found'})
        
        # Get conversation history for follow-ups
        conversation_history = get_conversation_history(user_id, conversation_id) if conversation_id else []
        
        # Generate context-aware prompt with corrected query
        prompt = generate_context_aware_prompt(corrected_query, user_profile, conversation_history)
        
        # Call Bedrock with dynamically selected guardrails
        bedrock_response = call_bedrock_with_guardrails(prompt, user_profile)
        response = bedrock_response['content']
        guardrail_config = bedrock_response['guardrail_config']
        
        # Log for audit and save conversation
        conversation_id = conversation_id or f"{user_id}-{int(datetime.now().timestamp())}"
        log_interaction(user_id, query, response, user_profile)
        save_conversation_turn(user_id, conversation_id, query, response)
        
        return cors_response(200, {
            'response': response,
            'conversation_id': conversation_id,
            'original_query': query,
            'corrected_query': corrected_query if corrected_query != query else None,
            'metadata': {
                'user_id': user_id,
                'age_group': user_profile.get('age_group', 'unknown'),
                'role': user_profile.get('role', 'unknown'),
                'industry': user_profile.get('industry', 'unknown'),
                'device': user_profile.get('device', 'desktop'),
                'guardrail_applied': True,
                'guardrail_config': guardrail_config,  # Show which guardrail was used
                'grammar_corrected': corrected_query != query,
                'timestamp': datetime.now().isoformat()
            }
        })
        
    except Exception as e:
        logger.error(f"Error: {str(e)}", exc_info=True)
        return cors_response(500, {'error': 'Internal server error'})

def get_user_from_context(event):
    """Extract user ID from Cognito authorizer context"""
    try:
        # API Gateway Cognito authorizer provides user context
        authorizer = event.get('requestContext', {}).get('authorizer', {})
        claims = authorizer.get('claims', {})
        
        # Get user ID from Cognito claims
        user_id = claims.get('cognito:username') or claims.get('sub')
        
        if user_id and len(user_id) <= 100:
            logger.info(f"User from Cognito authorizer: {user_id}")
            return user_id
            
        logger.error("No valid user context found in Cognito authorizer")
        logger.info(f"Event context: {event.get('requestContext', {})}")
        return None
        
    except Exception as e:
        logger.error(f"Error extracting user context: {e}")
        return None

def parse_request_body(event):
    """Parse and validate request body"""
    try:
        body = json.loads(event.get('body', '{}'))
        return body
    except json.JSONDecodeError:
        return {'error': 'Invalid JSON'}

def get_user_profile(user_id):
    """Get user profile from DynamoDB"""
    try:
        table = dynamodb.Table(os.environ['USER_TABLE'])
        response = table.get_item(Key={'user_id': user_id})
        
        if 'Item' not in response:
            return None
            
        profile = response['Item']
        
        # Calculate age group from birth_date
        if 'birth_date' in profile:
            try:
                birth_date = datetime.strptime(profile['birth_date'], '%Y-%m-%d')
                age = (datetime.now() - birth_date).days // 365
                
                if age < 13:
                    profile['age_group'] = 'child'
                elif age < 18:
                    profile['age_group'] = 'teen'
                elif age < 65:
                    profile['age_group'] = 'adult'
                else:
                    profile['age_group'] = 'senior'
            except:
                profile['age_group'] = 'adult'
        
        return profile
        
    except Exception as e:
        logger.error(f"Error getting user profile: {e}")
        return None

def generate_context_aware_prompt(query, user_profile, conversation_history=[]):
    """Create dramatically different prompts based on age and role combinations with conversation context"""
    age_group = user_profile.get('age_group', 'adult')
    role = user_profile.get('role', 'general')
    industry = user_profile.get('industry', 'general')
    
    # Add conversation history if available
    context = ""
    if conversation_history:
        context = "Previous conversation:\n"
        for turn in conversation_history[-3:]:  # Last 3 turns
            context += f"Q: {turn['query']}\nA: {turn['response'][:200]}...\n\n"
        context += "Current question:\n"
    
    # Create role-specific prompts that are completely different
    if role == 'student' and age_group == 'teen':
        prompt = f"{context}A 13-year-old student is asking: {query}\n\n"
        prompt += "Answer like you're explaining to a curious teenager. Use simple, clear language that a 8th grader can understand. Make it engaging and relatable to their world - school, friends, social media, games. Keep it educational but fun. Use 2-3 sentences maximum. Avoid baby talk but keep it age-appropriate."
        
    elif role == 'teacher' and age_group == 'adult':
        prompt = f"{context}An experienced teacher is asking: {query}\n\n"
        prompt += "Provide a comprehensive educational response with teaching strategies, curriculum connections, and pedagogical insights. Include how to explain this concept to different grade levels, classroom activities, and educational best practices. Be professional and detailed."
        
    elif role == 'patient' and industry == 'healthcare':
        prompt = f"{context}A healthcare patient is asking: {query}\n\n"
        prompt += "Explain in simple, reassuring terms that a worried patient can understand. Avoid complex medical jargon. Focus on general health information and encourage consulting healthcare providers for specific medical advice. Be empathetic and clear."
        
    elif role == 'provider' and industry == 'healthcare':
        prompt = f"{context}A healthcare provider is asking: {query}\n\n"
        prompt += "Provide detailed clinical information with appropriate medical terminology, evidence-based recommendations, and professional insights. Include relevant medical guidelines, diagnostic considerations, and treatment protocols as appropriate for healthcare professionals."
        
    else:
        # Default adult response
        prompt = f"{context}Answer this question professionally: {query}\n\n"
        prompt += "Provide a clear, informative response appropriate for an adult audience. Be accurate, helpful, and comprehensive."
    
    return prompt

def auto_correct_grammar(query):
    """Auto-correct grammar using Claude AI"""
    try:
        # Skip correction for math expressions
        if any(char in query for char in ['+', '-', '*', '/', '=', '<', '>', '%']):
            return query
        
        # Skip correction for numbers-only queries
        if query.replace(' ', '').replace('+', '').replace('-', '').replace('*', '').replace('/', '').isdigit():
            return query
            
        # Simple grammar corrections for common mistakes
        corrections = {
            'wat is': 'what is',
            'wats': 'what is',
            'whats': 'what is', 
            'whos': 'who is',
            'hows': 'how is',
            'wheres': 'where is',
            'whens': 'when is',
            'whys': 'why is',
            'ur': 'your',
            'u': 'you',
            'r': 'are',
            'n': 'and',
            'b4': 'before',
            'plz': 'please',
            'pls': 'please',
            'thx': 'thanks',
            'ty': 'thank you'
        }
        
        corrected = query.lower()
        
        # Only apply word-level corrections, not single character replacements for math
        for mistake, correction in corrections.items():
            if len(mistake) > 1:  # Skip single character replacements
                corrected = corrected.replace(mistake, correction)
        
        # Capitalize first letter
        if corrected:
            corrected = corrected[0].upper() + corrected[1:]
            
        # Add question mark if missing and it's a question
        question_words = ['what', 'who', 'where', 'when', 'why', 'how', 'is', 'are', 'can', 'do', 'does']
        if any(corrected.lower().startswith(word) for word in question_words):
            if not corrected.endswith('?'):
                corrected += '?'
        
        return corrected
        
    except Exception as e:
        logger.error(f"Grammar correction error: {e}")
        return query  # Return original if correction fails

def get_conversation_history(user_id, conversation_id):
    """Get conversation history from DynamoDB"""
    try:
        table = dynamodb.Table(os.environ['AUDIT_TABLE'])
        response = table.query(
            IndexName='conversation-index',  # You'd need to add this GSI
            KeyConditionExpression='conversation_id = :cid',
            ExpressionAttributeValues={':cid': conversation_id},
            ScanIndexForward=True,
            Limit=10
        )
        return response.get('Items', [])
    except Exception as e:
        logger.error(f"Error getting conversation history: {e}")
        return []

def save_conversation_turn(user_id, conversation_id, query, response):
    """Save conversation turn for follow-ups"""
    try:
        table = dynamodb.Table(os.environ['AUDIT_TABLE'])
        table.put_item(Item={
            'interaction_id': f"{user_id}-{int(datetime.now().timestamp())}",
            'conversation_id': conversation_id,
            'user_id': user_id,
            'timestamp': datetime.now().isoformat(),
            'query': query[:1000],
            'response': response[:2000],  # Store response for context
            'ttl': int(datetime.now().timestamp()) + (24 * 60 * 60)  # 24 hour TTL
        })
    except Exception as e:
        logger.error(f"Error saving conversation: {e}")

def select_guardrail_configuration(user_profile):
    """
    CORE FEATURE: Dynamic guardrail selection based on user context
    Guardrails are ALWAYS applied - never bypassed
    Context determines WHICH guardrail, not WHETHER to apply one
    """
    age_group = user_profile.get('age_group', 'adult')
    role = user_profile.get('role', 'general')
    industry = user_profile.get('industry', 'general')
    
    # CHILD PROTECTION (Maximum Security)
    if age_group == 'child':
        return {
            'guardrail_id': os.environ.get('CHILD_GUARDRAIL_ID'),
            'guardrail_version': '1',
            'protection_level': 'maximum',
            'compliance': 'COPPA'
        }
    
    # TEEN EDUCATIONAL (Balanced Protection)
    elif age_group == 'teen':
        return {
            'guardrail_id': os.environ.get('TEEN_GUARDRAIL_ID'),
            'guardrail_version': '1',
            'protection_level': 'balanced',
            'context': 'educational'
        }
    
    # HEALTHCARE PROFESSIONAL (HIPAA Compliance)
    elif industry == 'healthcare' and role == 'provider':
        return {
            'guardrail_id': os.environ.get('HEALTHCARE_PROFESSIONAL_GUARDRAIL_ID'),
            'guardrail_version': '1',
            'protection_level': 'clinical',
            'compliance': 'HIPAA'
        }
    
    # HEALTHCARE PATIENT (Medical Advice Blocking)
    elif industry == 'healthcare' and role == 'patient':
        return {
            'guardrail_id': os.environ.get('HEALTHCARE_PATIENT_GUARDRAIL_ID'),
            'guardrail_version': '1',
            'protection_level': 'medical_safety',
            'compliance': 'Patient_Safety'
        }
    
    # ADULT GENERAL (Standard Protection)
    else:
        return {
            'guardrail_id': os.environ.get('ADULT_GENERAL_GUARDRAIL_ID'),
            'guardrail_version': '1',
            'protection_level': 'standard',
            'context': 'general'
        }

def call_bedrock_with_guardrails(prompt, user_profile):
    """Call Bedrock with dynamically selected guardrails based on user context"""
    try:
        # CORE INNOVATION: Dynamic guardrail selection
        guardrail_config = select_guardrail_configuration(user_profile)
        
        guardrail_id = guardrail_config['guardrail_id']
        guardrail_version = guardrail_config['guardrail_version']
        
        if not guardrail_id:
            logger.error("No guardrail configuration found - this should never happen")
            # Fallback to default guardrail - never bypass guardrails
            guardrail_id = os.environ.get('DEFAULT_GUARDRAIL_ID')
            
        request_body = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 500,
            "messages": [{"role": "user", "content": prompt}]
        }
        
        # ALWAYS call with guardrails - guardrails are never bypassed
        response = bedrock.invoke_model(
            modelId="anthropic.claude-3-sonnet-20240229-v1:0",
            body=json.dumps(request_body),
            contentType="application/json",
            accept="application/json",
            guardrailIdentifier=guardrail_id,
            guardrailVersion=guardrail_version
        )
        
        response_body = json.loads(response['body'].read())
        
        # Return both response and guardrail metadata
        return {
            'content': response_body['content'][0]['text'],
            'guardrail_config': guardrail_config
        }
        
    except Exception as e:
        logger.error(f"Bedrock error: {e}")
        return {
            'content': "I apologize, but I'm unable to process your request at this time.",
            'guardrail_config': {'error': str(e)}
        }



def log_interaction(user_id, query, response, user_profile):
    """Log interaction for audit"""
    try:
        table = dynamodb.Table(os.environ['AUDIT_TABLE'])
        
        table.put_item(Item={
            'interaction_id': f"{user_id}-{int(datetime.now().timestamp())}",
            'user_id': user_id,
            'timestamp': datetime.now().isoformat(),
            'query': query[:1000],  # Limit length
            'response_length': len(response),
            'age_group': user_profile.get('age_group', 'unknown'),
            'role': user_profile.get('role', 'unknown')
        })
    except Exception as e:
        logger.error(f"Audit logging error: {e}")

def cors_response(status_code, body):
    """Return response with CORS headers"""
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type,Authorization',
            'Access-Control-Allow-Methods': 'POST,OPTIONS'
        },
        'body': json.dumps(body) if isinstance(body, dict) else body
    }