class StravaOauthService
  BASE_URL = "https://www.strava.com"
  AUTHORIZE_URL = "#{BASE_URL}/oauth/authorize".freeze
  TOKEN_URL = "#{BASE_URL}/oauth/token".freeze
  DEAUTHORIZE_URL = "#{BASE_URL}/oauth/deauthorize".freeze

  class Error < StandardError
  end

  def authorize_url(redirect_uri:)
    params = {
      client_id: client_id,
      redirect_uri: redirect_uri,
      response_type: "code",
      scope: "activity:read_all",
      approval_prompt: "auto"
    }
    "#{AUTHORIZE_URL}?#{params.to_query}"
  end

  def exchange_code(code:, credential:, redirect_uri:)
    response =
      post_token(
        client_id: client_id,
        client_secret: client_secret,
        code: code,
        grant_type: "authorization_code",
        redirect_uri: redirect_uri
      )

    save_tokens(credential, response)
  end

  def refresh_token!(credential)
    response =
      post_token(
        client_id: client_id,
        client_secret: client_secret,
        refresh_token: credential.refresh_token,
        grant_type: "refresh_token"
      )

    save_tokens(credential, response)
  end

  def deauthorize(credential)
    uri = URI(DEAUTHORIZE_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{credential.access_token}"

    http.request(request)
  end

  private

  def post_token(**params)
    uri = URI(TOKEN_URL)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri)
    request.set_form_data(params)

    response = http.request(request)
    body = JSON.parse(response.body)

    unless response.is_a?(Net::HTTPSuccess)
      raise Error, body["message"] || "OAuth error: #{response.code}"
    end

    body
  end

  def save_tokens(credential, response)
    credential.update!(
      access_token: response["access_token"],
      refresh_token: response["refresh_token"],
      token_expires_at: Time.zone.at(response["expires_at"])
    )
  end

  def client_id
    ENV["STRAVA_CLIENT_ID"] ||
      Rails.application.credentials.dig(:strava, :client_id) ||
      raise(Error, "STRAVA_CLIENT_ID not configured")
  end

  def client_secret
    ENV["STRAVA_CLIENT_SECRET"] ||
      Rails.application.credentials.dig(:strava, :client_secret) ||
      raise(Error, "STRAVA_CLIENT_SECRET not configured")
  end
end
