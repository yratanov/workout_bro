module RequestHelpers
  def sign_in(user)
    post session_path, params: { email: user.email, password: "password" }
  end
end

class ActionDispatch::IntegrationTest
  include RequestHelpers
end
