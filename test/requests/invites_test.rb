require "test_helper"

class InvitesTest < ActionDispatch::IntegrationTest
  setup do
    @owner = users(:john)
    @invite = @owner.invites.create!
  end

  test "GET /use-invite/:token returns success for valid unused invite" do
    get use_invite_path(token: @invite.token)
    assert_response :success
  end

  test "GET /use-invite/:token shows registration form" do
    get use_invite_path(token: @invite.token)
    assert_includes response.body, "Create Account"
  end

  test "GET /use-invite/:token returns 404 for invalid token" do
    get use_invite_path(token: "invalid")
    assert_response :not_found
  end

  test "GET /use-invite/:token redirects to login for already used invite" do
    @invite.update!(used_at: Time.current, used_by_user: users(:jane))
    get use_invite_path(token: @invite.token)
    assert_redirected_to new_session_path
  end

  test "GET /use-invite/:token redirects to root if already signed in" do
    sign_in(users(:jane))
    get use_invite_path(token: @invite.token)
    assert_redirected_to root_path
  end

  test "POST /use-invite/:token creates a new user" do
    assert_difference "User.count", 1 do
      post use_invite_path(token: @invite.token), params: valid_user_params
    end
  end

  test "POST /use-invite/:token marks the invite as used" do
    post use_invite_path(token: @invite.token), params: valid_user_params
    @invite.reload
    assert @invite.used?
    assert_equal "newuser@example.com", @invite.used_by_user.email
    assert @invite.used_at.present?
  end

  test "POST /use-invite/:token signs in the new user" do
    post use_invite_path(token: @invite.token), params: valid_user_params
    follow_redirect!
    assert_response :success
  end

  test "POST /use-invite/:token redirects to setup path" do
    post use_invite_path(token: @invite.token), params: valid_user_params
    assert_redirected_to setup_path
  end

  test "POST /use-invite/:token sets wizard_step to 1" do
    post use_invite_path(token: @invite.token), params: valid_user_params
    new_user = User.find_by(email: "newuser@example.com")
    assert_equal 1, new_user.wizard_step
  end

  test "POST /use-invite/:token does not create a user with missing email" do
    assert_no_difference "User.count" do
      post use_invite_path(token: @invite.token),
           params: {
             user: {
               email: "",
               password: "password123",
               password_confirmation: "password123"
             }
           }
    end
  end

  test "POST /use-invite/:token does not create a user with mismatched passwords" do
    assert_no_difference "User.count" do
      post use_invite_path(token: @invite.token),
           params: {
             user: {
               email: "test@example.com",
               password: "password123",
               password_confirmation: "different"
             }
           }
    end
  end

  test "POST /use-invite/:token renders the form again with errors for invalid params" do
    post use_invite_path(token: @invite.token),
         params: {
           user: {
             email: "",
             password: "password123",
             password_confirmation: "password123"
           }
         }
    assert_response :unprocessable_entity
  end

  test "POST /use-invite/:token redirects to root if already signed in" do
    sign_in(users(:jane))
    post use_invite_path(token: @invite.token), params: valid_user_params
    assert_redirected_to root_path
  end

  test "POST /use-invite/:token redirects to login for already used invite" do
    @invite.update!(used_at: Time.current, used_by_user: users(:jane))
    post use_invite_path(token: @invite.token), params: valid_user_params
    assert_redirected_to new_session_path
  end

  private

  def valid_user_params
    {
      user: {
        first_name: "New",
        last_name: "User",
        email: "newuser@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
  end
end
