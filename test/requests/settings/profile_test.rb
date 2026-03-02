require "test_helper"

class Settings::ProfileTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
  end

  test "GET /settings/profile returns success" do
    get settings_profile_path
    assert_response :success
  end

  test "GET /settings/profile displays the current user email" do
    get settings_profile_path
    assert_includes response.body, @user.email_address
  end

  test "PATCH /settings/profile updates the email address" do
    patch settings_profile_path,
          params: {
            user: {
              email_address: "newemail@example.com"
            }
          }
    @user.reload
    assert_equal "newemail@example.com", @user.email_address
    assert_redirected_to settings_profile_path
    follow_redirect!
    assert_includes response.body, "Profile updated successfully"
  end

  test "PATCH /settings/profile normalizes the email address" do
    patch settings_profile_path,
          params: {
            user: {
              email_address: "  UPPERCASE@EXAMPLE.COM  "
            }
          }
    @user.reload
    assert_equal "uppercase@example.com", @user.email_address
  end

  test "PATCH /settings/profile updates the name" do
    patch settings_profile_path,
          params: {
            user: {
              first_name: "Updated",
              last_name: "Name"
            }
          }
    @user.reload
    assert_equal "Updated", @user.first_name
    assert_equal "Name", @user.last_name
  end

  test "PATCH /settings/profile does not update with blank email" do
    original_email = @user.email_address
    patch settings_profile_path, params: { user: { email_address: "" } }
    @user.reload
    assert_equal original_email, @user.email_address
    assert_response :unprocessable_entity
  end

  test "GET /settings/profile redirects to login when not authenticated" do
    delete session_path
    get settings_profile_path
    assert_redirected_to new_session_path
  end
end
