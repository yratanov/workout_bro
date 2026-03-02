require "test_helper"

class SessionsTest < ActionDispatch::IntegrationTest
  setup { @user = users(:john) }

  test "POST /session with valid credentials redirects to root path" do
    post session_path,
         params: {
           email_address: @user.email_address,
           password: "password"
         }
    assert_redirected_to root_path
  end

  test "POST /session with invalid credentials redirects to login with alert" do
    post session_path,
         params: {
           email_address: @user.email_address,
           password: "wrongpassword"
         }
    assert_redirected_to new_session_path
    assert_equal I18n.t("controllers.sessions.invalid_credentials"),
                 flash[:alert]
  end

  test "POST /session with non-existent user redirects to login with alert" do
    post session_path,
         params: {
           email_address: "nonexistent@example.com",
           password: "password"
         }
    assert_redirected_to new_session_path
    assert_equal I18n.t("controllers.sessions.invalid_credentials"),
                 flash[:alert]
  end

  test "DELETE /session terminates the session and redirects to login" do
    sign_in(@user)
    delete session_path
    assert_redirected_to new_session_path
  end
end
