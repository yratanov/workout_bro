require "rails_helper"

describe "Invites" do
  fixtures :users

  let(:owner) { users(:john) }
  let!(:invite) { owner.invites.create! }

  describe "GET /use-invite/:token" do
    it "returns success for valid unused invite" do
      get use_invite_path(token: invite.token)
      expect(response).to have_http_status(:success)
    end

    it "shows registration form" do
      get use_invite_path(token: invite.token)
      expect(response.body).to include("Create Account")
    end

    it "returns 404 for invalid token" do
      get use_invite_path(token: "invalid")
      expect(response).to have_http_status(:not_found)
    end

    it "redirects to login for already used invite" do
      invite.update!(used_at: Time.current, used_by_user: users(:jane))
      get use_invite_path(token: invite.token)
      expect(response).to redirect_to(new_session_path)
    end

    it "redirects to root if already signed in" do
      sign_in(users(:jane))
      get use_invite_path(token: invite.token)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST /use-invite/:token" do
    let(:valid_params) do
      {
        user: {
          first_name: "New",
          last_name: "User",
          email_address: "newuser@example.com",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    it "creates a new user" do
      expect {
        post use_invite_path(token: invite.token), params: valid_params
      }.to change(User, :count).by(1)
    end

    it "marks the invite as used" do
      post use_invite_path(token: invite.token), params: valid_params
      invite.reload
      expect(invite.used?).to be true
      expect(invite.used_by_user.email_address).to eq("newuser@example.com")
      expect(invite.used_at).to be_present
    end

    it "signs in the new user" do
      post use_invite_path(token: invite.token), params: valid_params
      # Verify user is signed in by following redirect to setup
      follow_redirect!
      expect(response).to have_http_status(:success)
    end

    it "redirects to setup path" do
      post use_invite_path(token: invite.token), params: valid_params
      expect(response).to redirect_to(setup_path)
    end

    it "sets wizard_step to 1" do
      post use_invite_path(token: invite.token), params: valid_params
      new_user = User.find_by(email_address: "newuser@example.com")
      expect(new_user.wizard_step).to eq(1)
    end

    context "with invalid params" do
      it "does not create a user with missing email" do
        expect {
          post use_invite_path(token: invite.token),
               params: {
                 user: {
                   email_address: "",
                   password: "password123",
                   password_confirmation: "password123"
                 }
               }
        }.not_to change(User, :count)
      end

      it "does not create a user with mismatched passwords" do
        expect {
          post use_invite_path(token: invite.token),
               params: {
                 user: {
                   email_address: "test@example.com",
                   password: "password123",
                   password_confirmation: "different"
                 }
               }
        }.not_to change(User, :count)
      end

      it "renders the form again with errors" do
        post use_invite_path(token: invite.token),
             params: {
               user: {
                 email_address: "",
                 password: "password123",
                 password_confirmation: "password123"
               }
             }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it "redirects to root if already signed in" do
      sign_in(users(:jane))
      post use_invite_path(token: invite.token), params: valid_params
      expect(response).to redirect_to(root_path)
    end

    it "redirects to login for already used invite" do
      invite.update!(used_at: Time.current, used_by_user: users(:jane))
      post use_invite_path(token: invite.token), params: valid_params
      expect(response).to redirect_to(new_session_path)
    end
  end
end
