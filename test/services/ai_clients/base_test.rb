require "test_helper"

class AiClients::BaseTest < ActiveSupport::TestCase
  setup { @base = AiClients::Base.new }

  test "generate raises NotImplementedError" do
    assert_raises(NotImplementedError) { @base.generate("test prompt") }
  end

  test "generate_chat raises NotImplementedError" do
    assert_raises(NotImplementedError) do
      @base.generate_chat([{ role: "user", text: "Hello" }])
    end
  end

  test "generate_chat_stream raises NotImplementedError" do
    assert_raises(NotImplementedError) do
      @base.generate_chat_stream([{ role: "user", text: "Hello" }])
    end
  end
end
