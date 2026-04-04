require "test_helper"

class StravaOauthServiceTest < ActiveSupport::TestCase
  setup do
    @service = StravaOauthService.new
    @user = users(:john)
    @credential = @user.strava_credential
    ENV["STRAVA_CLIENT_ID"] = "test_client_id"
    ENV["STRAVA_CLIENT_SECRET"] = "test_client_secret"
  end

  teardown do
    ENV.delete("STRAVA_CLIENT_ID")
    ENV.delete("STRAVA_CLIENT_SECRET")
  end

  test "authorize_url builds correct URL with required params" do
    url = @service.authorize_url(redirect_uri: "http://localhost/callback")

    assert_includes url, "https://www.strava.com/oauth/authorize"
    assert_includes url, "client_id=test_client_id"
    assert_includes url, "response_type=code"
    assert_includes url, "scope=activity%3Aread_all"
    assert_includes url, "redirect_uri=http%3A%2F%2Flocalhost%2Fcallback"
  end

  test "exchange_code saves tokens to credential" do
    stub_token_response(
      access_token: "new_access",
      refresh_token: "new_refresh",
      expires_at: 1.hour.from_now.to_i
    )

    @service.exchange_code(
      code: "auth_code",
      credential: @credential,
      redirect_uri: "http://localhost/callback"
    )

    @credential.reload
    assert_equal "new_access", @credential.access_token
    assert_equal "new_refresh", @credential.refresh_token
    assert_not_nil @credential.token_expires_at
  end

  test "refresh_token! updates tokens on credential" do
    @credential.update!(
      access_token: "old_access",
      refresh_token: "old_refresh",
      token_expires_at: 1.hour.ago
    )

    stub_token_response(
      access_token: "refreshed_access",
      refresh_token: "refreshed_refresh",
      expires_at: 1.hour.from_now.to_i
    )

    @service.refresh_token!(@credential)

    @credential.reload
    assert_equal "refreshed_access", @credential.access_token
    assert_equal "refreshed_refresh", @credential.refresh_token
  end

  test "exchange_code raises Error on failed response" do
    stub_token_error("Bad Request")

    assert_raises(StravaOauthService::Error) do
      @service.exchange_code(
        code: "bad_code",
        credential: @credential,
        redirect_uri: "http://localhost/callback"
      )
    end
  end

  test "raises Error when STRAVA_CLIENT_ID is not configured" do
    ENV.delete("STRAVA_CLIENT_ID")

    error =
      assert_raises(StravaOauthService::Error) do
        @service.authorize_url(redirect_uri: "http://localhost/callback")
      end
    assert_includes error.message, "STRAVA_CLIENT_ID"
  end

  private

  def stub_token_response(access_token:, refresh_token:, expires_at:)
    response =
      stub(
        body: {
          access_token: access_token,
          refresh_token: refresh_token,
          expires_at: expires_at,
          token_type: "Bearer"
        }.to_json
      )
    response.stubs(:is_a?).with(Net::HTTPSuccess).returns(true)
    Net::HTTP.any_instance.stubs(:request).returns(response)
  end

  def stub_token_error(message)
    response = stub(body: { message: message }.to_json, code: "400")
    response.stubs(:is_a?).with(Net::HTTPSuccess).returns(false)
    Net::HTTP.any_instance.stubs(:request).returns(response)
  end
end
