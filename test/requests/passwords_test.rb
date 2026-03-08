require "test_helper"

class PasswordsTest < ActionDispatch::IntegrationTest
  include ActionMailer::TestHelper

  setup { @user = users(:john) }

  test "GET /passwords/new returns success" do
    get new_password_path
    assert_response :success
  end

  test "POST /passwords with valid email sends reset email and redirects" do
    assert_enqueued_emails 1 do
      post passwords_path, params: { email: @user.email }
    end
    assert_redirected_to new_session_path
  end

  test "POST /passwords with non-existent email redirects without sending email" do
    assert_no_enqueued_emails do
      post passwords_path, params: { email: "nonexistent@example.com" }
    end
    assert_redirected_to new_session_path
  end

  test "GET /passwords/:token/edit with valid token returns success" do
    token = @user.password_reset_token
    get edit_password_path(token)
    assert_response :success
  end

  test "GET /passwords/:token/edit with invalid token redirects to new password path" do
    get edit_password_path("invalid_token")
    assert_redirected_to new_password_path
  end

  test "PATCH /passwords/:token with valid token and matching passwords updates password" do
    token = @user.password_reset_token
    patch password_path(token),
          params: {
            password: "newpassword",
            password_confirmation: "newpassword"
          }
    assert_redirected_to new_session_path
    assert @user.reload.authenticate("newpassword")
  end

  test "PATCH /passwords/:token with valid token but mismatched passwords redirects back" do
    token = @user.password_reset_token
    patch password_path(token),
          params: {
            password: "newpassword",
            password_confirmation: "different"
          }
    assert_redirected_to edit_password_path(token)
  end

  test "PATCH /passwords/:token with invalid token redirects to new password path" do
    patch password_path("invalid_token"),
          params: {
            password: "newpassword",
            password_confirmation: "newpassword"
          }
    assert_redirected_to new_password_path
  end
end
