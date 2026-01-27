require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  fixtures :users

  let(:user) { users(:one) }

  describe "POST /session" do
    context "with valid credentials" do
      it "redirects to root path" do
        post session_path, params: { email_address: user.email_address, password: "password" }

        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid credentials" do
      it "redirects to login with alert" do
        post session_path, params: { email_address: user.email_address, password: "wrongpassword" }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t("controllers.sessions.invalid_credentials"))
      end
    end

    context "with non-existent user" do
      it "redirects to login with alert" do
        post session_path, params: { email_address: "nonexistent@example.com", password: "password" }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq(I18n.t("controllers.sessions.invalid_credentials"))
      end
    end
  end

  describe "DELETE /session" do
    before { sign_in(user) }

    it "terminates the session and redirects to login" do
      delete session_path

      expect(response).to redirect_to(new_session_path)
    end
  end
end
