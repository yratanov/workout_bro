require 'rails_helper'

RSpec.describe "Settings::Profile", type: :request do
  fixtures :users

  let(:user) { users(:one) }

  before do
    sign_in(user)
  end

  describe "GET /settings/profile" do
    it "returns success" do
      get settings_profile_path
      expect(response).to have_http_status(:success)
    end

    it "displays the current user email" do
      get settings_profile_path
      expect(response.body).to include(user.email_address)
    end
  end

  describe "PATCH /settings/profile" do
    context "with valid params" do
      it "updates the email address" do
        patch settings_profile_path, params: {
          user: { email_address: "newemail@example.com" }
        }

        user.reload
        expect(user.email_address).to eq("newemail@example.com")
        expect(response).to redirect_to(settings_profile_path)
        follow_redirect!
        expect(response.body).to include("Profile updated successfully")
      end

      it "normalizes the email address" do
        patch settings_profile_path, params: {
          user: { email_address: "  UPPERCASE@EXAMPLE.COM  " }
        }

        user.reload
        expect(user.email_address).to eq("uppercase@example.com")
      end
    end

    context "with invalid params" do
      it "does not update with blank email" do
        original_email = user.email_address

        patch settings_profile_path, params: {
          user: { email_address: "" }
        }

        user.reload
        expect(user.email_address).to eq(original_email)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  context "when not authenticated" do
    before do
      delete session_path
    end

    it "redirects to login" do
      get settings_profile_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
