require "test_helper"

class Settings::GarminTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
  end

  test "GET /settings/garmin returns success" do
    get settings_garmin_path
    assert_response :success
  end

  test "GET /settings/garmin displays the username when credential exists" do
    @user.garmin_credential.update!(
      username: "garmin_user",
      password: "secret123"
    )
    get settings_garmin_path
    assert_includes response.body, "garmin_user"
  end

  test "GET /settings/garmin does not display the password when credential exists" do
    @user.garmin_credential.update!(
      username: "garmin_user",
      password: "secret123"
    )
    get settings_garmin_path
    assert_not_includes response.body, "secret123"
  end

  test "GET /settings/garmin shows password hint when password is set" do
    @user.garmin_credential.update!(
      username: "garmin_user",
      password: "secret123"
    )
    get settings_garmin_path
    assert_includes response.body, "Password is saved"
  end

  test "GET /settings/garmin returns success with empty form when no credential" do
    get settings_garmin_path
    assert_response :success
  end

  test "PATCH /settings/garmin creates a new credential with valid params" do
    assert_difference "ThirdPartyCredential.count", 1 do
      patch settings_garmin_path,
            params: {
              third_party_credential: {
                username: "new_garmin_user",
                password: "new_password"
              }
            }
    end
    credential = @user.garmin_credential
    assert_equal "new_garmin_user", credential.username
    assert_equal "new_password", credential.encrypted_password
    assert_redirected_to settings_garmin_path
  end

  test "PATCH /settings/garmin updates an existing credential" do
    @user.garmin_credential.update!(username: "old_user", password: "old_pass")
    patch settings_garmin_path,
          params: {
            third_party_credential: {
              username: "updated_user",
              password: "updated_pass"
            }
          }
    credential = @user.garmin_credential.reload
    assert_equal "updated_user", credential.username
    assert_equal "updated_pass", credential.encrypted_password
  end

  test "PATCH /settings/garmin keeps existing password when password field is blank" do
    @user.garmin_credential.update!(
      username: "garmin_user",
      password: "original_password"
    )
    patch settings_garmin_path,
          params: {
            third_party_credential: {
              username: "updated_user",
              password: ""
            }
          }
    credential = @user.garmin_credential.reload
    assert_equal "updated_user", credential.username
    assert_equal "original_password", credential.encrypted_password
  end

  test "PATCH /settings/garmin updates username while preserving password when password is blank" do
    @user.garmin_credential.update!(
      username: "garmin_user",
      password: "original_password"
    )
    patch settings_garmin_path,
          params: {
            third_party_credential: {
              username: "new_username",
              password: ""
            }
          }
    credential = @user.garmin_credential.reload
    assert_equal "new_username", credential.username
    assert_equal "original_password", credential.encrypted_password
  end

  test "PATCH /settings/garmin saves username without password" do
    patch settings_garmin_path,
          params: {
            third_party_credential: {
              username: "just_username",
              password: ""
            }
          }
    credential = @user.garmin_credential
    assert_equal "just_username", credential.username
    assert_nil credential.encrypted_password
    assert_redirected_to settings_garmin_path
  end

  test "GET /settings/garmin does not expose other user credentials" do
    other_user = users(:jane)
    other_user.garmin_credential.update!(
      username: "other_user_garmin",
      password: "other_secret"
    )
    get settings_garmin_path
    assert_not_includes response.body, "other_user_garmin"
  end

  test "PATCH /settings/garmin cannot update other user credentials" do
    other_user = users(:jane)
    other_credential = other_user.garmin_credential
    other_credential.update!(username: "other_user", password: "other_pass")
    patch settings_garmin_path,
          params: {
            third_party_credential: {
              username: "hacked_user"
            }
          }
    assert_equal "other_user", other_credential.reload.username
  end

  test "GET /settings/garmin redirects to login when not authenticated" do
    delete session_path
    get settings_garmin_path
    assert_redirected_to new_session_path
  end

  test "POST /settings/garmin/sync runs the sync service and redirects with success message" do
    @user.garmin_credential.update!(
      username: "garmin_user",
      password: "secret123"
    )
    Open3.stubs(:capture2).returns(
      [{ activities: [] }.to_json, stub(success?: true, exitstatus: 0)]
    )

    post sync_settings_garmin_path
    assert_redirected_to settings_garmin_path
    follow_redirect!
    assert_includes response.body, "Sync complete"
  end

  test "POST /settings/garmin/sync shows imported and skipped counts" do
    @user.garmin_credential.update!(
      username: "garmin_user",
      password: "secret123"
    )
    activities_json = {
      activities: [
        {
          started_at: "2024-01-15T08:30:00",
          distance_meters: 5000,
          duration_seconds: 1800
        }
      ]
    }.to_json
    Open3.stubs(:capture2).returns(
      [activities_json, stub(success?: true, exitstatus: 0)]
    )

    post sync_settings_garmin_path
    assert_redirected_to settings_garmin_path
    follow_redirect!
    assert_includes response.body, "1 imported"
    assert_includes response.body, "0 skipped"
  end

  test "POST /settings/garmin/sync shows error message when sync fails" do
    @user.garmin_credential.update!(
      username: "garmin_user",
      password: "secret123"
    )
    Open3.stubs(:capture2).returns(
      [
        { error: "Invalid credentials" }.to_json,
        stub(success?: true, exitstatus: 0)
      ]
    )

    post sync_settings_garmin_path
    assert_redirected_to settings_garmin_path
    follow_redirect!
    assert_includes response.body, "Sync failed"
  end

  test "POST /settings/garmin/sync shows missing credentials error when not configured" do
    post sync_settings_garmin_path
    assert_redirected_to settings_garmin_path
    follow_redirect!
    assert_includes response.body, "configure your Garmin username and password"
  end
end
