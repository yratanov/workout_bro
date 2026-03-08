module LoginHelpers
  def login_as(user)
    visit new_session_path
    fill_in "email", with: user.email
    fill_in "password", with: "password"
    click_button "Sign in"
    assert_no_current_path new_session_path
  end
end
