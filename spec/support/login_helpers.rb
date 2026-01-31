module LoginHelpers
  def login_as(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_button "Sign in"
    # Wait for Turbo Drive navigation to complete
    expect(page).not_to have_current_path(new_session_path)
  end
end

RSpec.configure { |config| config.include LoginHelpers, type: :feature }
