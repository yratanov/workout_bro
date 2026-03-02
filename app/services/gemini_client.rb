# frozen_string_literal: true

# Backward-compatible wrapper around AiClients::Gemini.
# New code should use AiClient.for(user) instead.
class GeminiClient < AiClients::Gemini
  Error = AiClients::Base::Error
  AuthenticationError = AiClients::Base::AuthenticationError
  RateLimitError = AiClients::Base::RateLimitError
  DailyRequestLimitError = AiClients::Base::DailyRequestLimitError

  DAILY_REQUEST_LIMIT = AiClients::Gemini::DAILY_REQUEST_LIMIT
end
