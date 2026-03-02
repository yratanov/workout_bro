# frozen_string_literal: true

module AiClient
  def self.for(user)
    case user.ai_provider
    when "gemini"
      AiClients::Gemini.new(api_key: user.ai_api_key, model: user.ai_model)
    else
      raise ArgumentError, "Unknown AI provider: #{user.ai_provider}"
    end
  end
end
