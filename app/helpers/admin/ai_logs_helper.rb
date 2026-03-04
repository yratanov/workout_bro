module Admin
  module AiLogsHelper
    def format_ai_log_text(text)
      parsed = JSON.parse(text)
      JSON.pretty_generate(parsed)
    rescue JSON::ParserError
      text
    end
  end
end
