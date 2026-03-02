require "test_helper"

class Admin::InvitesTest < ActionDispatch::IntegrationTest
  setup do
    @admin_user = users(:john)
    @regular_user = users(:jane)
  end

  # === as admin ===

  test "GET /admin/invites returns success as admin" do
    sign_in(@admin_user)
    get admin_invites_path
    assert_response :success
  end

  test "GET /admin/invites displays user's invites as admin" do
    sign_in(@admin_user)
    invite = @admin_user.invites.create!
    get admin_invites_path
    assert_includes response.body, invite.token
  end

  test "POST /admin/invites creates a new invite as admin" do
    sign_in(@admin_user)
    assert_difference "@admin_user.invites.count", 1 do
      post admin_invites_path
    end
  end

  test "POST /admin/invites redirects to invites page with notice as admin" do
    sign_in(@admin_user)
    post admin_invites_path
    assert_redirected_to admin_invites_path
    follow_redirect!
    assert_includes response.body, I18n.t("controllers.admin.invites.created")
  end

  test "POST /admin/invites generates a unique token as admin" do
    sign_in(@admin_user)
    post admin_invites_path
    invite = @admin_user.invites.last
    assert invite.token.present?
    assert_equal 32, invite.token.length
  end

  test "DELETE /admin/invites/:id destroys the invite as admin" do
    sign_in(@admin_user)
    invite = @admin_user.invites.create!
    assert_difference "@admin_user.invites.count", -1 do
      delete invite_admin_invites_path(invite)
    end
  end

  test "DELETE /admin/invites/:id redirects to invites page as admin" do
    sign_in(@admin_user)
    invite = @admin_user.invites.create!
    delete invite_admin_invites_path(invite)
    assert_redirected_to admin_invites_path
  end

  test "DELETE /admin/invites/:id does not allow deleting other users invites as admin" do
    sign_in(@admin_user)
    other_invite = @regular_user.invites.create!
    delete invite_admin_invites_path(other_invite)
    assert_response :not_found
  end

  # === as regular user ===

  test "GET /admin/invites redirects as regular user" do
    sign_in(@regular_user)
    get admin_invites_path
    assert_redirected_to root_path
  end

  test "POST /admin/invites redirects as regular user" do
    sign_in(@regular_user)
    post admin_invites_path
    assert_redirected_to root_path
  end

  test "DELETE /admin/invites/:id redirects as regular user" do
    sign_in(@regular_user)
    invite = @admin_user.invites.create!
    delete invite_admin_invites_path(invite)
    assert_redirected_to root_path
  end
end
