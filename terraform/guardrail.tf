# ---------------------------------------------------------------------------
# Bedrock Guardrail — content moderation for guest book messages
# ---------------------------------------------------------------------------
# Blocks profanity and offensive/abusive language before an entry is stored.
# The guest book Lambda calls ApplyGuardrail on each submitted message; any
# intervention causes the whole message to be rejected.

resource "aws_bedrock_guardrail" "guestbook" {
  name                      = "${var.project_name}-guestbook-moderation"
  description               = "Blocks profanity and offensive language in guest book messages"
  blocked_input_messaging   = var.guardrail_blocked_message
  blocked_outputs_messaging = var.guardrail_blocked_message

  # Managed profanity word filter.
  word_policy_config {
    managed_word_lists_config {
      type = "PROFANITY"
    }
  }

  # Content filters catch broader insults / hate / harassment that the
  # profanity list alone may miss.
  content_policy_config {
    filters_config {
      type            = "INSULTS"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }

    filters_config {
      type            = "HATE"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }

    filters_config {
      type            = "SEXUAL"
      input_strength  = "HIGH"
      output_strength = "HIGH"
    }
  }

  tags = {
    Name = "${var.project_name}-guestbook-moderation"
  }
}

# A published version is required to invoke the guardrail at runtime.
resource "aws_bedrock_guardrail_version" "guestbook" {
  guardrail_arn = aws_bedrock_guardrail.guestbook.guardrail_arn
  description   = "Published version used by the guest book Lambda"
}
