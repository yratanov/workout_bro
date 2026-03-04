# frozen_string_literal: true

module AiClient
  def self.for(user)
    return AiClients::Fake.new if use_fake?

    case user.ai_provider
    when "gemini"
      AiClients::Gemini.new(api_key: user.ai_api_key, model: user.ai_model)
    else
      raise ArgumentError, "Unknown AI provider: #{user.ai_provider}"
    end
  end

  def self.use_fake?
    Rails.env.development? && !ENV["AI_REAL"].present?
  end
end
