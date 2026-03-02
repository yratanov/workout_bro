require "test_helper"

class Settings::WeightsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
  end

  test "GET /settings/weights returns success" do
    get settings_weights_path
    assert_response :success
  end

  test "GET /settings/weights displays the weight settings form" do
    get settings_weights_path
    assert_includes response.body, "Weight Settings"
  end

  test "PATCH /settings/weights updates weight_unit" do
    patch settings_weights_path, params: { user: { weight_unit: "lbs" } }
    @user.reload
    assert_equal "lbs", @user.weight_unit
    assert_redirected_to settings_weights_path
  end

  test "PATCH /settings/weights updates weight_min" do
    patch settings_weights_path, params: { user: { weight_min: 5.0 } }
    @user.reload
    assert_equal 5.0, @user.weight_min
  end

  test "PATCH /settings/weights updates weight_max" do
    patch settings_weights_path, params: { user: { weight_max: 200.0 } }
    @user.reload
    assert_equal 200.0, @user.weight_max
  end

  test "PATCH /settings/weights updates weight_step" do
    patch settings_weights_path, params: { user: { weight_step: 5.0 } }
    @user.reload
    assert_equal 5.0, @user.weight_step
  end

  test "PATCH /settings/weights displays success message" do
    patch settings_weights_path, params: { user: { weight_unit: "lbs" } }
    follow_redirect!
    assert_includes response.body, "Weight settings updated successfully"
  end

  test "PATCH /settings/weights does not update with invalid weight_unit" do
    patch settings_weights_path, params: { user: { weight_unit: "invalid" } }
    @user.reload
    assert_equal "kg", @user.weight_unit
    assert_response :unprocessable_entity
  end

  test "PATCH /settings/weights updates weight_min to zero" do
    patch settings_weights_path, params: { user: { weight_min: 0 } }
    @user.reload
    assert_equal 0, @user.weight_min
    assert_redirected_to settings_weights_path
  end

  test "PATCH /settings/weights does not update with negative weight_min" do
    patch settings_weights_path, params: { user: { weight_min: -1 } }
    @user.reload
    assert_equal 2.5, @user.weight_min
    assert_response :unprocessable_entity
  end

  test "PATCH /settings/weights does not update with weight_max less than weight_min" do
    patch settings_weights_path,
          params: {
            user: {
              weight_min: 50,
              weight_max: 25
            }
          }
    @user.reload
    assert_equal 100.0, @user.weight_max
    assert_response :unprocessable_entity
  end

  test "PATCH /settings/weights does not update with zero weight_step" do
    patch settings_weights_path, params: { user: { weight_step: 0 } }
    @user.reload
    assert_equal 2.5, @user.weight_step
    assert_response :unprocessable_entity
  end

  test "GET /settings/weights redirects to login when not authenticated" do
    delete session_path
    get settings_weights_path
    assert_redirected_to new_session_path
  end
end
