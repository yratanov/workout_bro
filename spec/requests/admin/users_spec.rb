describe "Admin::Users" do
  fixtures :users

  let(:admin_user) { users(:john) }
  let(:regular_user) { users(:jane) }

  describe "as admin" do
    before { sign_in(admin_user) }

    describe "GET /admin/users" do
      it "returns success" do
        get admin_users_path
        expect(response).to have_http_status(:success)
      end

      it "displays all users" do
        get admin_users_path
        expect(response.body).to include(admin_user.email_address)
        expect(response.body).to include(regular_user.email_address)
      end

      it "displays user roles" do
        get admin_users_path
        expect(response.body).to include(
          I18n.t("admin.users.index.roles.admin")
        )
        expect(response.body).to include(I18n.t("admin.users.index.roles.user"))
      end

      it "shows edit link for each user" do
        get admin_users_path
        expect(response.body).to include(edit_admin_user_path(admin_user))
        expect(response.body).to include(edit_admin_user_path(regular_user))
      end

      it "shows delete button for other users but not self" do
        get admin_users_path
        expect(response.body).to include(admin_user_path(regular_user))
        # The delete form for self should not be present
        expect(response.body.scan(admin_user_path(admin_user)).count).to eq(1) # Only edit link
      end
    end

    describe "GET /admin/users/:id/edit" do
      it "returns success" do
        get edit_admin_user_path(regular_user)
        expect(response).to have_http_status(:success)
      end

      it "displays the edit form" do
        get edit_admin_user_path(regular_user)
        expect(response.body).to include(regular_user.email_address)
        expect(response.body).to include(I18n.t("admin.users.edit.edit_user"))
      end
    end

    describe "PATCH /admin/users/:id" do
      it "updates the user email" do
        patch admin_user_path(regular_user),
              params: {
                user: {
                  email_address: "newemail@example.com"
                }
              }
        expect(regular_user.reload.email_address).to eq("newemail@example.com")
      end

      it "updates the user name" do
        patch admin_user_path(regular_user),
              params: {
                user: {
                  first_name: "Updated",
                  last_name: "Name"
                }
              }
        regular_user.reload
        expect(regular_user.first_name).to eq("Updated")
        expect(regular_user.last_name).to eq("Name")
      end

      it "redirects to users index with notice" do
        patch admin_user_path(regular_user),
              params: {
                user: {
                  email_address: "newemail@example.com"
                }
              }
        expect(response).to redirect_to(admin_users_path)
        follow_redirect!
        expect(response.body).to include(
          I18n.t("controllers.admin.users.updated")
        )
      end

      it "renders edit on validation error" do
        patch admin_user_path(regular_user),
              params: {
                user: {
                  email_address: ""
                }
              }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "does not allow duplicate emails" do
        patch admin_user_path(regular_user),
              params: {
                user: {
                  email_address: admin_user.email_address
                }
              }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "DELETE /admin/users/:id" do
      it "destroys the user" do
        expect { delete admin_user_path(regular_user) }.to change(
          User,
          :count
        ).by(-1)
      end

      it "redirects to users index with notice" do
        delete admin_user_path(regular_user)
        expect(response).to redirect_to(admin_users_path)
        follow_redirect!
        expect(response.body).to include(
          I18n.t("controllers.admin.users.destroyed")
        )
      end

      it "does not allow deleting self" do
        expect { delete admin_user_path(admin_user) }.not_to change(
          User,
          :count
        )
        expect(response).to redirect_to(admin_users_path)
        follow_redirect!
        expect(response.body).to include(
          I18n.t("controllers.admin.users.cannot_delete_self")
        )
      end
    end
  end

  describe "as regular user" do
    before { sign_in(regular_user) }

    it "redirects from GET /admin/users" do
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects from GET /admin/users/:id/edit" do
      get edit_admin_user_path(admin_user)
      expect(response).to redirect_to(root_path)
    end

    it "redirects from PATCH /admin/users/:id" do
      patch admin_user_path(admin_user),
            params: {
              user: {
                email_address: "hack@example.com"
              }
            }
      expect(response).to redirect_to(root_path)
      expect(admin_user.reload.email_address).to eq("john@example.com")
    end

    it "redirects from DELETE /admin/users/:id" do
      delete admin_user_path(admin_user)
      expect(response).to redirect_to(root_path)
      expect(User.exists?(admin_user.id)).to be true
    end
  end

  describe "when not authenticated" do
    it "redirects to login" do
      get admin_users_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
