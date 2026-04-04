require "test_helper"

class Settings::StravaTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
    ENV["STRAVA_CLIENT_ID"] = "test_client_id"
    ENV["STRAVA_CLIENT_SECRET"] = "test_client_secret"
  end

  teardown do
    ENV.delete("STRAVA_CLIENT_ID")
    ENV.delete("STRAVA_CLIENT_SECRET")
  end

  test "GET /settings/strava returns success" do
    get settings_strava_path
    assert_response :success
  end

  test "GET /settings/strava shows connect button when not connected" do
    get settings_strava_path
    assert_includes response.body, "Connect with Strava"
  end

  test "GET /settings/strava shows connected status when connected" do
    connect_strava
    get settings_strava_path
    assert_includes response.body, "Connected"
    assert_includes response.body, "Disconnect"
  end

  test "GET /settings/strava/connect redirects to Strava OAuth" do
    get connect_settings_strava_path
    assert_response :redirect
    assert_includes response.location, "strava.com/oauth/authorize"
    assert_includes response.location, "test_client_id"
  end

  test "GET /settings/strava/callback saves tokens and redirects" do
    stub_token_response

    get callback_settings_strava_path, params: { code: "auth_code" }
    assert_redirected_to settings_strava_path

    credential = @user.strava_credential.reload
    assert_equal "test_access_token", credential.access_token
    assert_equal "test_refresh_token", credential.refresh_token
  end

  test "GET /settings/strava/callback shows error on OAuth failure" do
    stub_token_error

    get callback_settings_strava_path, params: { code: "bad_code" }
    assert_redirected_to settings_strava_path
    follow_redirect!
    assert_includes response.body, "Failed to connect Strava"
  end

  test "DELETE /settings/strava/disconnect removes credential" do
    connect_strava

    assert_difference "ThirdPartyCredential.count", -1 do
      # Stub deauthorize call
      Net::HTTP
        .any_instance
        .stubs(:request)
        .returns(stub(body: "{}", code: "200"))
      delete disconnect_settings_strava_path
    end

    assert_redirected_to settings_strava_path
  end

  test "POST /settings/strava/sync runs sync and redirects with success" do
    connect_strava
    stub_strava_activities_api([].to_json)

    post sync_settings_strava_path
    assert_redirected_to settings_strava_path
    follow_redirect!
    assert_includes response.body, "Sync complete"
  end

  test "POST /settings/strava/sync shows error when not connected" do
    post sync_settings_strava_path
    assert_redirected_to settings_strava_path
    follow_redirect!
    assert_includes response.body, "connect your Strava account"
  end

  test "GET /settings/strava redirects to login when not authenticated" do
    delete session_path
    get settings_strava_path
    assert_redirected_to new_session_path
  end

  private

  def connect_strava
    @user.strava_credential.update!(
      access_token: "test_access_token",
      refresh_token: "test_refresh_token",
      token_expires_at: 1.hour.from_now
    )
  end

  def stub_token_response
    response =
      stub(
        body: {
          access_token: "test_access_token",
          refresh_token: "test_refresh_token",
          expires_at: 1.hour.from_now.to_i,
          token_type: "Bearer"
        }.to_json
      )
    response.stubs(:is_a?).with(Net::HTTPSuccess).returns(true)
    Net::HTTP.any_instance.stubs(:request).returns(response)
  end

  def stub_token_error
    response = stub(body: { message: "invalid code" }.to_json, code: "400")
    response.stubs(:is_a?).with(Net::HTTPSuccess).returns(false)
    Net::HTTP.any_instance.stubs(:request).returns(response)
  end

  def stub_strava_activities_api(json_response)
    response = Net::HTTPSuccess.new("1.1", "200", "OK")
    response.stubs(:body).returns(json_response)
    Net::HTTP.any_instance.stubs(:request).returns(response)
  end
end
