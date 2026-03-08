require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  test "allows a user to sign in with valid credentials" do
    visit new_session_path

    fill_in "email", with: users(:john).email
    fill_in "password", with: "password"
    click_button "Sign in"

    assert_text "Workouts"
    assert_current_path root_path
  end

  test "redirects unauthenticated users to login" do
    visit workouts_path

    assert_current_path new_session_path
  end
end
