require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  setup do
    @user = users(:john)
    @mail = PasswordsMailer.reset(@user)
  end

  test "renders the subject" do
    assert_equal "Reset your password", @mail.subject
  end

  test "sends to the user's email" do
    assert_equal [@user.email_address], @mail.to
  end

  test "renders the sender email" do
    assert_equal ["from@example.com"], @mail.from
  end

  test "includes the password reset link in the body" do
    assert_includes @mail.body.encoded, "password"
  end
end
