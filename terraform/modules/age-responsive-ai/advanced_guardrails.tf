# Advanced Guardrail Configurations for Age-Responsive Context-Aware AI
# Using only supported Terraform AWS provider attributes

# 1. Child Protection Guardrail (Maximum Security - COPPA Compliant)
resource "aws_bedrock_guardrail" "child_protection" {
  name                      = "child-protection-guardrail"
  description              = "Maximum protection for users under 13 with comprehensive COPPA-compliant content blocking"
  blocked_input_messaging  = "I can't help with that request. Let's talk about something fun and safe!"
  blocked_outputs_messaging = "I can't share that information. How about we discuss something more appropriate?"

  content_policy_config {
    filters_config {
      type             = "VIOLENCE"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "SEXUAL"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "HATE"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "INSULTS"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "MISCONDUCT"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "PROMPT_ATTACK"
      input_strength   = "HIGH"
      output_strength  = "NONE"
    }
  }

  word_policy_config {
    words_config {
      text = "kill"
    }
    words_config {
      text = "weapon"
    }
    words_config {
      text = "scary"
    }
    words_config {
      text = "violence"
    }
    managed_word_lists_config {
      type = "PROFANITY"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "AdultContent"
      definition = "Any content inappropriate for children including violence, adult themes, scary content, or mature topics"
      examples   = ["horror stories", "violent games", "adult relationships", "scary movies"]
      type       = "DENY"
    }
    topics_config {
      name       = "PersonalInformationSharing"
      definition = "Requests for personal information from children - COPPA compliance"
      examples   = ["what's your address", "tell me your phone number", "where do you live"]
      type       = "DENY"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      type   = "ADDRESS"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "EMAIL"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "PHONE"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "NAME"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "USERNAME"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "PASSWORD"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "DRIVER_ID"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "LICENSE_PLATE"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "VEHICLE_IDENTIFICATION_NUMBER"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "AGE"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "IP_ADDRESS"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "MAC_ADDRESS"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "URL"
      action = "ANONYMIZE"
    }
    
    regexes_config {
      name        = "school_id"
      pattern     = "\\b[Ss]tudent[\\s]*[Ii][Dd][:\\s]*\\d+\\b"
      action      = "BLOCK"
      description = "Student ID blocking for privacy"
    }
    regexes_config {
      name        = "grade_level"
      pattern     = "\\b[Gg]rade[\\s]*\\d+\\b"
      action      = "ANONYMIZE"
      description = "Grade level anonymization"
    }
  }

  tags = {
    Name        = "Child Protection Guardrail"
    UserType    = "Child"
    Protection  = "Maximum"
    Compliance  = "COPPA"
    Environment = var.environment
  }
}

# 2. Teen Educational Guardrail (Balanced Protection)
resource "aws_bedrock_guardrail" "teen_educational" {
  name                      = "teen-educational-guardrail"
  description              = "Balanced protection for teens with educational context allowances"
  blocked_input_messaging  = "I can't help with that request. Let's discuss something educational instead!"
  blocked_outputs_messaging = "I can't share that information. How about we explore a learning topic?"

  content_policy_config {
    filters_config {
      type             = "SEXUAL"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "VIOLENCE"
      input_strength   = "MEDIUM"
      output_strength  = "MEDIUM"
    }
    filters_config {
      type             = "HATE"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "MISCONDUCT"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "PROMPT_ATTACK"
      input_strength   = "HIGH"
      output_strength  = "NONE"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "SelfHarmPrevention"
      definition = "Content that could encourage self-harm or dangerous behavior"
      examples   = ["how to hurt yourself", "suicide methods", "dangerous challenges"]
      type       = "DENY"
    }
    topics_config {
      name       = "SubstanceAbuse"
      definition = "Content promoting illegal substance use or underage drinking"
      examples   = ["how to get drugs", "underage drinking", "substance abuse"]
      type       = "DENY"
    }
  }

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      type   = "EMAIL"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PHONE"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "PASSWORD"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "CREDIT_DEBIT_CARD_NUMBER"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "CREDIT_DEBIT_CARD_CVV"
      action = "BLOCK"
    }
    
    regexes_config {
      name        = "student_id"
      pattern     = "\\b[Ss]tudent[\\s]*[Ii][Dd][:\\s]*\\d+\\b"
      action      = "ANONYMIZE"
      description = "Student ID anonymization only"
    }
  }

  tags = {
    Name        = "Teen Educational Guardrail"
    UserType    = "Teen"
    Protection  = "Balanced"
    Context     = "Educational"
    Environment = var.environment
  }
}

# 3. Healthcare Professional Guardrail (HIPAA Compliant)
resource "aws_bedrock_guardrail" "healthcare_professional" {
  name                      = "healthcare-professional-guardrail"
  description              = "HIPAA-compliant guardrail for healthcare providers with clinical context"
  blocked_input_messaging  = "This request contains content that cannot be processed. Please rephrase your clinical question."
  blocked_outputs_messaging = "I cannot provide this information due to content policies. Please consult clinical guidelines."

  content_policy_config {
    filters_config {
      type             = "SEXUAL"
      input_strength   = "MEDIUM"
      output_strength  = "MEDIUM"
    }
    filters_config {
      type             = "VIOLENCE"
      input_strength   = "LOW"
      output_strength  = "LOW"
    }
    filters_config {
      type             = "MISCONDUCT"
      input_strength   = "MEDIUM"
      output_strength  = "MEDIUM"
    }
    filters_config {
      type             = "PROMPT_ATTACK"
      input_strength   = "HIGH"
      output_strength  = "NONE"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "PatientPrivacyViolation"
      definition = "Sharing specific patient information without consent"
      examples   = ["John Smith has cancer", "Patient in room 302 has diabetes"]
      type       = "DENY"
    }
    topics_config {
      name       = "UnauthorizedMedicalAdvice"
      definition = "Providing medical advice outside scope of practice"
      examples   = ["prescribe this medication without evaluation", "ignore clinical guidelines"]
      type       = "DENY"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      type   = "ADDRESS"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "EMAIL"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PHONE"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "NAME"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "AGE"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "USERNAME"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PASSWORD"
      action = "BLOCK"
    }
    
    regexes_config {
      name        = "medical_record_number"
      pattern     = "\\bMRN[:\\s]*\\d+\\b"
      action      = "ANONYMIZE"
      description = "Medical record number anonymization"
    }
    regexes_config {
      name        = "patient_id"
      pattern     = "\\bPID[:\\s]*\\d+\\b"
      action      = "ANONYMIZE"
      description = "Patient ID anonymization"
    }
    regexes_config {
      name        = "social_security"
      pattern     = "\\b\\d{3}-\\d{2}-\\d{4}\\b"
      action      = "BLOCK"
      description = "Social Security Number blocking"
    }
    regexes_config {
      name        = "insurance_id"
      pattern     = "\\b[Ii]nsurance[\\s]*[Ii][Dd][:\\s]*[A-Z0-9]+\\b"
      action      = "ANONYMIZE"
      description = "Insurance ID anonymization"
    }
  }

  tags = {
    Name        = "Healthcare Professional Guardrail"
    UserType    = "Healthcare_Professional"
    Compliance  = "HIPAA"
    Industry    = "Healthcare"
    Environment = var.environment
  }
}

# 4. Healthcare Patient Guardrail (Medical Advice Protection)
resource "aws_bedrock_guardrail" "healthcare_patient" {
  name                      = "healthcare-patient-guardrail"
  description              = "Patient-focused guardrail blocking medical advice and diagnoses"
  blocked_input_messaging  = "I can't provide medical advice. Please consult with your healthcare provider."
  blocked_outputs_messaging = "I cannot share medical recommendations. Please speak with a qualified healthcare professional."

  content_policy_config {
    filters_config {
      type             = "SEXUAL"
      input_strength   = "MEDIUM"
      output_strength  = "MEDIUM"
    }
    filters_config {
      type             = "VIOLENCE"
      input_strength   = "MEDIUM"
      output_strength  = "MEDIUM"
    }
    filters_config {
      type             = "HATE"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "MISCONDUCT"
      input_strength   = "MEDIUM"
      output_strength  = "MEDIUM"
    }
    filters_config {
      type             = "PROMPT_ATTACK"
      input_strength   = "HIGH"
      output_strength  = "NONE"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "MedicalDiagnosis"
      definition = "Providing specific medical diagnoses based on symptoms"
      examples   = ["you have cancer", "this is diabetes", "you need surgery"]
      type       = "DENY"
    }
    topics_config {
      name       = "PrescriptionAdvice"
      definition = "Recommending specific medications or dosages"
      examples   = ["take 500mg of ibuprofen", "you need antibiotics", "stop your medication"]
      type       = "DENY"
    }
    topics_config {
      name       = "MedicalEmergencyAdvice"
      definition = "Providing emergency medical advice that requires professional intervention"
      examples   = ["treat this emergency at home", "ignore emergency symptoms"]
      type       = "DENY"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      type   = "ADDRESS"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "EMAIL"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PHONE"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "NAME"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "AGE"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "USERNAME"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PASSWORD"
      action = "BLOCK"
    }
    
    regexes_config {
      name        = "insurance_number"
      pattern     = "\\b[Ii]nsurance[\\s]*[Nn]umber[:\\s]*[A-Z0-9]+\\b"
      action      = "ANONYMIZE"
      description = "Insurance number anonymization"
    }
    regexes_config {
      name        = "medical_condition"
      pattern     = "\\bI\\s+have\\s+[a-z]+\\s+(cancer|diabetes|hypertension)\\b"
      action      = "ANONYMIZE"
      description = "Personal medical condition anonymization"
    }
  }

  tags = {
    Name        = "Healthcare Patient Guardrail"
    UserType    = "Healthcare_Patient"
    Protection  = "Medical_Advice_Blocking"
    Industry    = "Healthcare"
    Environment = var.environment
  }
}

# 5. Adult General Guardrail (Standard Protection)
resource "aws_bedrock_guardrail" "adult_general" {
  name                      = "adult-general-guardrail"
  description              = "Standard protection for adult users with balanced filtering"
  blocked_input_messaging  = "I can't help with that request. Let's discuss something else."
  blocked_outputs_messaging = "I can't provide that information. How about we talk about something different?"

  content_policy_config {
    filters_config {
      type             = "SEXUAL"
      input_strength   = "MEDIUM"
      output_strength  = "MEDIUM"
    }
    filters_config {
      type             = "VIOLENCE"
      input_strength   = "MEDIUM"
      output_strength  = "MEDIUM"
    }
    filters_config {
      type             = "HATE"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "MISCONDUCT"
      input_strength   = "HIGH"
      output_strength  = "HIGH"
    }
    filters_config {
      type             = "PROMPT_ATTACK"
      input_strength   = "HIGH"
      output_strength  = "NONE"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "HarmfulInstructions"
      definition = "Instructions for illegal or harmful activities"
      examples   = ["how to make explosives", "illegal drug manufacturing", "hacking instructions"]
      type       = "DENY"
    }
    topics_config {
      name       = "IllegalActivities"
      definition = "Content promoting or instructing illegal activities"
      examples   = ["how to break laws", "illegal schemes", "criminal activities"]
      type       = "DENY"
    }
  }

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
  }

  sensitive_information_policy_config {
    pii_entities_config {
      type   = "ADDRESS"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "EMAIL"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PHONE"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "NAME"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "USERNAME"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "PASSWORD"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "DRIVER_ID"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "LICENSE_PLATE"
      action = "ANONYMIZE"
    }
    pii_entities_config {
      type   = "CREDIT_DEBIT_CARD_CVV"
      action = "BLOCK"
    }
    pii_entities_config {
      type   = "CREDIT_DEBIT_CARD_NUMBER"
      action = "BLOCK"
    }
    
    regexes_config {
      name        = "employee_id"
      pattern     = "\\b[Ee]mployee[\\s]*[Ii][Dd][:\\s]*\\d+\\b"
      action      = "ANONYMIZE"
      description = "Employee ID anonymization"
    }
    regexes_config {
      name        = "api_key"
      pattern     = "\\b[Aa][Pp][Ii][\\s]*[Kk]ey[:\\s]*[A-Za-z0-9]+\\b"
      action      = "BLOCK"
      description = "API key blocking for security"
    }
  }

  tags = {
    Name        = "Adult General Guardrail"
    UserType    = "Adult"
    Protection  = "Standard"
    Environment = var.environment
  }
}

# Guardrail Version Management
resource "aws_bedrock_guardrail_version" "child_protection_v1" {
  guardrail_arn = aws_bedrock_guardrail.child_protection.guardrail_arn
  description   = "Production version for child protection"
}

resource "aws_bedrock_guardrail_version" "teen_educational_v1" {
  guardrail_arn = aws_bedrock_guardrail.teen_educational.guardrail_arn
  description   = "Production version for teen educational content"
}

resource "aws_bedrock_guardrail_version" "healthcare_professional_v1" {
  guardrail_arn = aws_bedrock_guardrail.healthcare_professional.guardrail_arn
  description   = "Production version for healthcare professionals"
}

resource "aws_bedrock_guardrail_version" "healthcare_patient_v1" {
  guardrail_arn = aws_bedrock_guardrail.healthcare_patient.guardrail_arn
  description   = "Production version for healthcare patients"
}

resource "aws_bedrock_guardrail_version" "adult_general_v1" {
  guardrail_arn = aws_bedrock_guardrail.adult_general.guardrail_arn
  description   = "Production version for general adult users"
}