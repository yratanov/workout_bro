require 'rails_helper'

RSpec.describe "Settings::Garmin", type: :request do
  fixtures :users

  let(:user) { users(:one) }

  before do
    sign_in(user)
  end

  describe "GET /settings/garmin" do
    it "returns success" do
      get settings_garmin_path
      expect(response).to have_http_status(:success)
    end

    context "when credential exists" do
      before do
        user.garmin_credential.update!(username: "garmin_user", password: "secret123")
      end

      it "displays the username" do
        get settings_garmin_path
        expect(response.body).to include("garmin_user")
      end

      it "does not display the password" do
        get settings_garmin_path
        expect(response.body).not_to include("secret123")
      end

      it "shows password hint when password is set" do
        get settings_garmin_path
        expect(response.body).to include("Password is saved")
      end
    end

    context "when credential does not exist" do
      it "returns success with empty form" do
        get settings_garmin_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "PATCH /settings/garmin" do
    context "with valid params" do
      it "creates a new credential" do
        expect {
          patch settings_garmin_path, params: {
            third_party_credential: {
              username: "new_garmin_user",
              password: "new_password"
            }
          }
        }.to change(ThirdPartyCredential, :count).by(1)

        credential = user.garmin_credential
        expect(credential.username).to eq("new_garmin_user")
        expect(credential.encrypted_password).to eq("new_password")
        expect(response).to redirect_to(settings_garmin_path)
      end

      it "updates an existing credential" do
        user.garmin_credential.update!(username: "old_user", password: "old_pass")

        patch settings_garmin_path, params: {
          third_party_credential: {
            username: "updated_user",
            password: "updated_pass"
          }
        }

        credential = user.garmin_credential.reload
        expect(credential.username).to eq("updated_user")
        expect(credential.encrypted_password).to eq("updated_pass")
      end

      it "keeps existing password when password field is blank" do
        user.garmin_credential.update!(username: "garmin_user", password: "original_password")

        patch settings_garmin_path, params: {
          third_party_credential: {
            username: "updated_user",
            password: ""
          }
        }

        credential = user.garmin_credential.reload
        expect(credential.username).to eq("updated_user")
        expect(credential.encrypted_password).to eq("original_password")
      end

      it "updates username while preserving password when password is blank" do
        user.garmin_credential.update!(username: "garmin_user", password: "original_password")

        patch settings_garmin_path, params: {
          third_party_credential: {
            username: "new_username",
            password: ""
          }
        }

        credential = user.garmin_credential.reload
        expect(credential.username).to eq("new_username")
        expect(credential.encrypted_password).to eq("original_password")
      end
    end

    context "with only username" do
      it "saves username without password" do
        patch settings_garmin_path, params: {
          third_party_credential: {
            username: "just_username",
            password: ""
          }
        }

        credential = user.garmin_credential
        expect(credential.username).to eq("just_username")
        expect(credential.encrypted_password).to be_nil
        expect(response).to redirect_to(settings_garmin_path)
      end
    end
  end

  describe "credential isolation" do
    let(:other_user) { users(:two) }

    it "does not expose other user credentials" do
      other_user.garmin_credential.update!(username: "other_user_garmin", password: "other_secret")

      get settings_garmin_path
      expect(response.body).not_to include("other_user_garmin")
    end

    it "cannot update other user credentials" do
      other_credential = other_user.garmin_credential
      other_credential.update!(username: "other_user", password: "other_pass")

      patch settings_garmin_path, params: {
        third_party_credential: {
          username: "hacked_user"
        }
      }

      other_credential.reload
      expect(other_credential.username).to eq("other_user")
    end
  end

  context "when not authenticated" do
    before do
      delete session_path
    end

    it "redirects to login" do
      get settings_garmin_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "POST /settings/garmin/sync" do
    context "when credentials are configured" do
      before do
        user.garmin_credential.update!(username: "garmin_user", password: "secret123")
      end

      it "runs the sync service and redirects with success message" do
        allow(Open3).to receive(:capture2).and_return(
          [ { activities: [] }.to_json, instance_double(Process::Status, success?: true, exitstatus: 0) ]
        )

        post sync_settings_garmin_path

        expect(response).to redirect_to(settings_garmin_path)
        follow_redirect!
        expect(response.body).to include("Sync complete")
      end

      it "shows imported and skipped counts" do
        activities_json = {
          activities: [
            { started_at: "2024-01-15T08:30:00", distance_meters: 5000, duration_seconds: 1800 }
          ]
        }.to_json

        allow(Open3).to receive(:capture2).and_return(
          [ activities_json, instance_double(Process::Status, success?: true, exitstatus: 0) ]
        )

        post sync_settings_garmin_path

        expect(response).to redirect_to(settings_garmin_path)
        follow_redirect!
        expect(response.body).to include("1 imported")
        expect(response.body).to include("0 skipped")
      end

      it "shows error message when sync fails" do
        allow(Open3).to receive(:capture2).and_return(
          [ { error: "Invalid credentials" }.to_json, instance_double(Process::Status, success?: true, exitstatus: 0) ]
        )

        post sync_settings_garmin_path

        expect(response).to redirect_to(settings_garmin_path)
        follow_redirect!
        expect(response.body).to include("Sync failed")
      end
    end

    context "when credentials are not configured" do
      it "shows missing credentials error" do
        post sync_settings_garmin_path

        expect(response).to redirect_to(settings_garmin_path)
        follow_redirect!
        expect(response.body).to include("configure your Garmin username and password")
      end
    end
  end
end
