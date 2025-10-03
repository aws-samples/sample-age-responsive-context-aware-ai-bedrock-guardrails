# Bedrock Guardrail Resources
resource "aws_bedrock_guardrail" "demo_guardrail" {
  name                      = "responsive-ai-demo-guardrail"
  description              = "Guardrail for blocking harmful content and hallucinations"
  blocked_input_messaging  = "I can't process that request due to safety guidelines."
  blocked_outputs_messaging = "I can't provide that information due to safety guidelines."

  content_policy_config {
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
      input_strength  = "MEDIUM"
      output_strength = "MEDIUM"
      type           = "INSULTS"
    }
    filters_config {
      input_strength  = "HIGH"
      output_strength = "HIGH"
      type           = "MISCONDUCT"
    }
    filters_config {
      input_strength  = "MEDIUM"
      output_strength = "NONE"
      type           = "PROMPT_ATTACK"
    }
  }

  topic_policy_config {
    topics_config {
      name       = "Harmful Instructions"
      examples   = ["How to make explosives", "How to hack systems"]
      type       = "DENY"
      definition = "Instructions for illegal or harmful activities"
    }
    topics_config {
      name       = "Fictional Information"
      examples   = ["Who is the CEO of Mars?", "Prime Minister of Jupiter"]
      type       = "DENY"
      definition = "Requests for information about fictional entities presented as real"
    }
  }

  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
    words_config {
      text = "CEO of Mars"
    }
    words_config {
      text = "Prime Minister of Jupiter"
    }
  }
}

resource "aws_bedrock_guardrail_version" "demo_guardrail_version" {
  guardrail_arn = aws_bedrock_guardrail.demo_guardrail.guardrail_arn
  description   = "Version 1 of the demo guardrail"
}