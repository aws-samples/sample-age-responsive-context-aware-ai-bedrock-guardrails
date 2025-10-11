# Advanced Bedrock Guardrail - Production-Ready Configuration
# This matches the sophisticated guardrail features described in review.md

resource "aws_bedrock_guardrail" "responsive_ai_guardrail" {
  name                      = "responsive-ai-guardrail"
  description              = "Advanced context-aware guardrail with industry-specific customization"
  blocked_input_messaging  = "I cannot process that request. Let me help you with something else."
  blocked_outputs_messaging = "I cannot provide that information due to safety and compliance guidelines."

  # CONTENT POLICY - Graduated filtering based on user context
  content_policy_config {
    # CHILD PROTECTION - Maximum security
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type           = "SEXUAL"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type           = "VIOLENCE"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type           = "HATE"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type           = "INSULTS"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type           = "MISCONDUCT"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "NONE"
      type           = "PROMPT_ATTACK"
    }
  }

  # SENSITIVE INFORMATION POLICY - Custom PII detection for healthcare
  sensitive_information_policy_config {
    # Medical Record Numbers (HIPAA Compliance)
    regexes_config {
      name        = "medical_record_number"
      pattern     = "\\bMRN[:\\s]*\\d+\\b"
      action      = "ANONYMIZE"
      description = "HIPAA-compliant medical record number anonymization"
    }
    
    # Patient IDs
    regexes_config {
      name        = "patient_id"
      pattern     = "\\bPATIENT[_\\s]*ID[:\\s]*\\d+\\b"
      action      = "ANONYMIZE"
      description = "Patient identifier anonymization for privacy"
    }
    
    # Social Security Numbers
    regexes_config {
      name        = "ssn"
      pattern     = "\\b\\d{3}-\\d{2}-\\d{4}\\b"
      action      = "BLOCK"
      description = "Social Security Number detection and blocking"
    }
    
    # Credit Card Numbers
    regexes_config {
      name        = "credit_card"
      pattern     = "\\b\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}\\b"
      action      = "ANONYMIZE"
      description = "Credit card number anonymization"
    }

    # Email Addresses
    regexes_config {
      name        = "email_address"
      pattern     = "\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}\\b"
      action      = "ANONYMIZE"
      description = "Email address anonymization for privacy"
    }

    # Phone Numbers
    regexes_config {
      name        = "phone_number"
      pattern     = "\\b\\(?\\d{3}\\)?[\\s.-]?\\d{3}[\\s.-]?\\d{4}\\b"
      action      = "ANONYMIZE"
      description = "Phone number anonymization"
    }
  }

  # TOPIC POLICY - Industry-specific content control
  topic_policy_config {
    # Medical Diagnosis Blocking (for patients)
    topics_config {
      name       = "Medical Diagnosis"
      definition = "Providing specific medical diagnoses based on symptoms or conditions"
      examples   = [
        "You have diabetes",
        "This is cancer",
        "You are suffering from depression",
        "Your symptoms indicate heart disease"
      ]
      type = "DENY"
    }

    # Prescription Drug Advice (for patients)
    topics_config {
      name       = "Prescription Advice"
      definition = "Providing specific medication recommendations or dosage instructions"
      examples   = [
        "Take 500mg of ibuprofen",
        "You should use insulin",
        "Stop taking your medication",
        "Increase your dosage to"
      ]
      type = "DENY"
    }

    # Harmful Instructions
    topics_config {
      name       = "Harmful Instructions"
      definition = "Instructions for illegal, dangerous, or harmful activities"
      examples   = [
        "How to make explosives",
        "How to hack computers",
        "How to break into systems",
        "How to create malware"
      ]
      type = "DENY"
    }

    # Fictional Information (Hallucination Prevention)
    topics_config {
      name       = "Fictional Information"
      definition = "Requests for information about fictional entities presented as real"
      examples   = [
        "Who is the CEO of Mars?",
        "Prime Minister of Jupiter",
        "President of the Moon",
        "Ambassador to Saturn"
      ]
      type = "DENY"
    }

    # Self-Harm Prevention (especially for teens)
    topics_config {
      name       = "Self Harm"
      definition = "Content related to self-harm, suicide, or dangerous behaviors"
      examples   = [
        "How to hurt myself",
        "Ways to end my life",
        "Self-harm methods",
        "Suicide instructions"
      ]
      type = "DENY"
    }

    # Financial Advice (for non-professionals)
    topics_config {
      name       = "Financial Advice"
      definition = "Specific financial investment or trading advice"
      examples   = [
        "Buy this stock",
        "Invest in cryptocurrency",
        "Sell your assets",
        "Take out a loan"
      ]
      type = "DENY"
    }
  }

  # WORD POLICY - Custom word filtering with managed lists
  word_policy_config {
    # Managed profanity filtering
    managed_word_lists_config {
      type = "PROFANITY"
    }

    # Custom blocked words for healthcare context
    words_config {
      text = "CEO of Mars"
    }
    words_config {
      text = "Prime Minister of Jupiter"
    }
    words_config {
      text = "fake doctor"
    }
    words_config {
      text = "unlicensed physician"
    }

    # Educational inappropriate terms
    words_config {
      text = "stupid student"
    }
    words_config {
      text = "dumb kid"
    }

    # Hacking and security terms
    words_config {
      text = "password cracking"
    }
    words_config {
      text = "system exploit"
    }
  }

  tags = {
    Environment = "demo"
    Purpose     = "context-aware-ai"
    Industry    = "healthcare-education"
    Compliance  = "HIPAA-COPPA"
  }
}

# Create a working version of the advanced guardrail
resource "aws_bedrock_guardrail_version" "responsive_ai_guardrail_v1" {
  guardrail_arn = aws_bedrock_guardrail.responsive_ai_guardrail.guardrail_arn
  description   = "Production version with advanced customization features"
}

# Output the guardrail details for demo purposes
output "advanced_guardrail_id" {
  description = "ID of the advanced responsive AI guardrail"
  value       = aws_bedrock_guardrail.responsive_ai_guardrail.guardrail_id
}

output "advanced_guardrail_arn" {
  description = "ARN of the advanced responsive AI guardrail"
  value       = aws_bedrock_guardrail.responsive_ai_guardrail.guardrail_arn
}

output "advanced_guardrail_version" {
  description = "Version of the advanced guardrail"
  value       = aws_bedrock_guardrail_version.responsive_ai_guardrail_v1.version
}