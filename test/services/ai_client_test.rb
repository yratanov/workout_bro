require "test_helper"

class AiClientTest < ActiveSupport::TestCase
  test "returns a Gemini client for gemini provider" do
    user =
      stub(
        "User",
        ai_provider: "gemini",
        ai_api_key: "test-key",
        ai_model: "gemini-2.0-flash"
      )
    client = AiClient.for(user)
    assert_instance_of AiClients::Gemini, client
  end

  test "raises ArgumentError for unknown provider" do
    user = stub("User", ai_provider: "openai")

    assert_raises(ArgumentError) { AiClient.for(user) }
  end
end
