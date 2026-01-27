require 'rails_helper'

describe "Settings::Invites" do
  fixtures :users

  let(:admin_user) { users(:john) }
  let(:regular_user) { users(:jane) }

  describe "as admin" do
    before do
      sign_in(admin_user)
    end

    describe "GET /settings/invites" do
      it "returns success" do
        get settings_invites_path
        expect(response).to have_http_status(:success)
      end

      it "displays user's invites" do
        invite = admin_user.invites.create!
        get settings_invites_path
        expect(response.body).to include(invite.token)
      end
    end

    describe "POST /settings/invites" do
      it "creates a new invite" do
        expect {
          post settings_invites_path
        }.to change(admin_user.invites, :count).by(1)
      end

      it "redirects to invites page with notice" do
        post settings_invites_path
        expect(response).to redirect_to(settings_invites_path)
        follow_redirect!
        expect(response.body).to include(I18n.t("controllers.settings.invites.created"))
      end

      it "generates a unique token" do
        post settings_invites_path
        invite = admin_user.invites.last
        expect(invite.token).to be_present
        expect(invite.token.length).to eq(32)
      end
    end

    describe "DELETE /settings/invites/:id" do
      let!(:invite) { admin_user.invites.create! }

      it "destroys the invite" do
        expect {
          delete invite_settings_invites_path(invite)
        }.to change(admin_user.invites, :count).by(-1)
      end

      it "redirects to invites page with notice" do
        delete invite_settings_invites_path(invite)
        expect(response).to redirect_to(settings_invites_path)
      end

      it "does not allow deleting other users' invites" do
        other_invite = regular_user.invites.create!

        delete invite_settings_invites_path(other_invite)
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "as regular user" do
    before do
      sign_in(regular_user)
    end

    it "redirects from GET /settings/invites" do
      get settings_invites_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects from POST /settings/invites" do
      post settings_invites_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects from DELETE /settings/invites/:id" do
      invite = admin_user.invites.create!
      delete invite_settings_invites_path(invite)
      expect(response).to redirect_to(root_path)
    end
  end
end
