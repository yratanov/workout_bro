describe "Passwords" do
  fixtures :users

  let(:user) { users(:john) }

  describe "GET /passwords/new" do
    it "returns success" do
      get new_password_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /passwords" do
    context "with valid email" do
      it "sends reset email and redirects" do
        expect {
          post passwords_path, params: { email_address: user.email_address }
        }.to have_enqueued_mail(PasswordsMailer, :reset)

        expect(response).to redirect_to(new_session_path)
      end
    end

    context "with non-existent email" do
      it "redirects without sending email (security: no email enumeration)" do
        expect {
          post passwords_path,
               params: {
                 email_address: "nonexistent@example.com"
               }
        }.not_to have_enqueued_mail(PasswordsMailer, :reset)

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /passwords/:token/edit" do
    context "with valid token" do
      it "returns success" do
        token = user.password_reset_token
        get edit_password_path(token)
        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid token" do
      it "redirects to new password path" do
        get edit_password_path("invalid_token")
        expect(response).to redirect_to(new_password_path)
      end
    end
  end

  describe "PATCH /passwords/:token" do
    context "with valid token and matching passwords" do
      it "updates password and redirects to login" do
        token = user.password_reset_token
        patch password_path(token),
              params: {
                password: "newpassword",
                password_confirmation: "newpassword"
              }

        expect(response).to redirect_to(new_session_path)
        expect(user.reload.authenticate("newpassword")).to be_truthy
      end
    end

    context "with valid token but mismatched passwords" do
      it "redirects back to edit with error" do
        token = user.password_reset_token
        patch password_path(token),
              params: {
                password: "newpassword",
                password_confirmation: "different"
              }

        expect(response).to redirect_to(edit_password_path(token))
      end
    end

    context "with invalid token" do
      it "redirects to new password path" do
        patch password_path("invalid_token"),
              params: {
                password: "newpassword",
                password_confirmation: "newpassword"
              }

        expect(response).to redirect_to(new_password_path)
      end
    end
  end
end
