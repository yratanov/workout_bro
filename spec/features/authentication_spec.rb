require 'rails_helper'

RSpec.describe "Authentication", type: :feature do
  fixtures :users

  describe "login" do
    it "allows a user to sign in with valid credentials" do
      visit new_session_path

      fill_in "email_address", with: users(:one).email_address
      fill_in "password", with: "password"
      click_button "Sign in"

      expect(page).to have_content("Workouts")
      expect(page).to have_current_path(root_path)
    end

    it "shows an error with invalid credentials" do
      visit new_session_path

      fill_in "email_address", with: users(:one).email_address
      fill_in "password", with: "wrongpassword"
      click_button "Sign in"

      expect(page).to have_content(I18n.t("controllers.sessions.invalid_credentials"))
    end
  end

  describe "logout" do
    it "allows a user to sign out" do
      login_as(users(:one))

      find('a[href="/session"][data-turbo-method="delete"]').click

      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "protected routes" do
    it "redirects unauthenticated users to login" do
      visit workouts_path

      expect(page).to have_current_path(new_session_path)
    end
  end
end
