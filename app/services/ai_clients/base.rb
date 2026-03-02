# frozen_string_literal: true

module AiClients
  class Base
    Error = Class.new(StandardError)
    AuthenticationError = Class.new(Error)
    RateLimitError = Class.new(Error)
    DailyRequestLimitError = Class.new(Error)

    def generate(prompt, generation_config: nil, log_context: nil)
      raise NotImplementedError
    end

    def generate_chat(
      messages,
      system_instruction: nil,
      generation_config: nil,
      log_context: nil
    )
      raise NotImplementedError
    end

    def generate_chat_stream(
      messages,
      system_instruction: nil,
      generation_config: nil,
      log_context: nil,
      &block
    )
      raise NotImplementedError
    end
  end
end
