require "test_helper"

class Admin::UsersTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:john)
    @regular_user = users(:jane)
  end

  # === as admin ===

  test "GET /admin/users returns success as admin" do
    sign_in(@admin_user)
    get admin_users_path
    assert_response :success
  end

  test "GET /admin/users displays all users as admin" do
    sign_in(@admin_user)
    get admin_users_path
    assert_includes response.body, @admin_user.email_address
    assert_includes response.body, @regular_user.email_address
  end

  test "GET /admin/users displays user roles as admin" do
    sign_in(@admin_user)
    get admin_users_path
    assert_includes response.body, I18n.t("admin.users.index.roles.admin")
    assert_includes response.body, I18n.t("admin.users.index.roles.user")
  end

  test "GET /admin/users shows edit link for each user as admin" do
    sign_in(@admin_user)
    get admin_users_path
    assert_includes response.body, edit_admin_user_path(@admin_user)
    assert_includes response.body, edit_admin_user_path(@regular_user)
  end

  test "GET /admin/users shows delete button for other users but not self as admin" do
    sign_in(@admin_user)
    get admin_users_path
    assert_includes response.body, admin_user_path(@regular_user)
    assert_equal 1, response.body.scan(admin_user_path(@admin_user)).count
  end

  test "GET /admin/users/:id/edit returns success as admin" do
    sign_in(@admin_user)
    get edit_admin_user_path(@regular_user)
    assert_response :success
  end

  test "GET /admin/users/:id/edit displays the edit form as admin" do
    sign_in(@admin_user)
    get edit_admin_user_path(@regular_user)
    assert_includes response.body, @regular_user.email_address
    assert_includes response.body, I18n.t("admin.users.edit.edit_user")
  end

  test "PATCH /admin/users/:id updates the user email as admin" do
    sign_in(@admin_user)
    patch admin_user_path(@regular_user),
          params: {
            user: {
              email_address: "newemail@example.com"
            }
          }
    assert_equal "newemail@example.com", @regular_user.reload.email_address
  end

  test "PATCH /admin/users/:id updates the user name as admin" do
    sign_in(@admin_user)
    patch admin_user_path(@regular_user),
          params: {
            user: {
              first_name: "Updated",
              last_name: "Name"
            }
          }
    @regular_user.reload
    assert_equal "Updated", @regular_user.first_name
    assert_equal "Name", @regular_user.last_name
  end

  test "PATCH /admin/users/:id redirects to users index with notice as admin" do
    sign_in(@admin_user)
    patch admin_user_path(@regular_user),
          params: {
            user: {
              email_address: "newemail@example.com"
            }
          }
    assert_redirected_to admin_users_path
    follow_redirect!
    assert_includes response.body, I18n.t("controllers.admin.users.updated")
  end

  test "PATCH /admin/users/:id renders edit on validation error as admin" do
    sign_in(@admin_user)
    patch admin_user_path(@regular_user),
          params: {
            user: {
              email_address: ""
            }
          }
    assert_response :unprocessable_entity
  end

  test "PATCH /admin/users/:id does not allow duplicate emails as admin" do
    sign_in(@admin_user)
    patch admin_user_path(@regular_user),
          params: {
            user: {
              email_address: @admin_user.email_address
            }
          }
    assert_response :unprocessable_entity
  end

  test "DELETE /admin/users/:id destroys the user as admin" do
    sign_in(@admin_user)
    assert_difference "User.count", -1 do
      delete admin_user_path(@regular_user)
    end
  end

  test "DELETE /admin/users/:id redirects to users index with notice as admin" do
    sign_in(@admin_user)
    delete admin_user_path(@regular_user)
    assert_redirected_to admin_users_path
    follow_redirect!
    assert_includes response.body, I18n.t("controllers.admin.users.destroyed")
  end

  test "DELETE /admin/users/:id does not allow deleting self as admin" do
    sign_in(@admin_user)
    assert_no_difference "User.count" do
      delete admin_user_path(@admin_user)
    end
    assert_redirected_to admin_users_path
    follow_redirect!
    assert_includes response.body,
                    I18n.t("controllers.admin.users.cannot_delete_self")
  end

  # === as regular user ===

  test "GET /admin/users redirects as regular user" do
    sign_in(@regular_user)
    get admin_users_path
    assert_redirected_to root_path
  end

  test "GET /admin/users/:id/edit redirects as regular user" do
    sign_in(@regular_user)
    get edit_admin_user_path(@admin_user)
    assert_redirected_to root_path
  end

  test "PATCH /admin/users/:id redirects as regular user" do
    sign_in(@regular_user)
    patch admin_user_path(@admin_user),
          params: {
            user: {
              email_address: "hack@example.com"
            }
          }
    assert_redirected_to root_path
    assert_equal "john@example.com", @admin_user.reload.email_address
  end

  test "DELETE /admin/users/:id redirects as regular user" do
    sign_in(@regular_user)
    delete admin_user_path(@admin_user)
    assert_redirected_to root_path
    assert User.exists?(@admin_user.id)
  end

  # === when not authenticated ===

  test "GET /admin/users redirects to login when not authenticated" do
    get admin_users_path
    assert_redirected_to new_session_path
  end
end
