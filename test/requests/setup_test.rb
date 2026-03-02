require "test_helper"

class SetupTest < ActionDispatch::IntegrationTest
  test "GET /setup redirects completed users to root" do
    @user = users(:john)
    sign_in(@user)

    get setup_path
    assert_redirected_to root_path
  end

  test "GET /setup shows account step when no users exist" do
    User.stubs(:count).returns(0)

    get setup_path
    assert_response :success
  end

  test "PATCH /setup account step with valid params creates user and redirects" do
    User.stubs(:count).returns(0)

    user_count_before = User.unscoped.count
    patch setup_path,
          params: {
            user: {
              first_name: "New",
              last_name: "User",
              email_address: "new@example.com",
              password: "password123",
              password_confirmation: "password123"
            }
          }
    user_count_after = User.unscoped.count

    assert_equal 1, user_count_after - user_count_before
    assert_redirected_to setup_path

    user = User.find_by(email_address: "new@example.com")
    assert_equal "admin", user.role
    assert_equal 1, user.wizard_step
  end

  test "PATCH /setup account step with invalid params returns 422" do
    User.stubs(:count).returns(0)

    user_count_before = User.unscoped.count
    patch setup_path,
          params: {
            user: {
              first_name: "New",
              last_name: "User",
              email_address: "",
              password: "password123",
              password_confirmation: "password123"
            }
          }
    user_count_after = User.unscoped.count

    assert_equal 0, user_count_after - user_count_before
    assert_response :unprocessable_entity
  end

  test "PATCH /setup language step updates locale" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 1)
    sign_in(@user)

    patch setup_path, params: { locale: "ru", advance: "1" }

    assert_redirected_to setup_path
    @user.reload
    assert_equal "ru", @user.locale
    assert_equal 2, @user.wizard_step
  end

  test "PATCH /setup exercises step with import enqueues job" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 2)
    sign_in(@user)

    assert_enqueued_with(job: ExercisesImportJob) do
      patch setup_path, params: { import_exercises: "1" }
    end

    assert_redirected_to setup_path
    @user.reload
    assert_equal 3, @user.wizard_step
  end

  test "PATCH /setup exercises step without import advances step" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 2)
    sign_in(@user)

    patch setup_path
    assert_redirected_to setup_path
    @user.reload
    assert_equal 3, @user.wizard_step
  end

  test "PATCH /setup garmin step with skip advances step" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 3)
    sign_in(@user)

    patch setup_path, params: { skip: "1" }
    assert_redirected_to setup_path
    @user.reload
    assert_equal 4, @user.wizard_step
  end

  test "PATCH /setup complete step marks setup as completed" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 4)
    sign_in(@user)

    patch setup_path
    assert_redirected_to root_path
    @user.reload
    assert @user.setup_completed?
  end

  test "PATCH /setup complete step redirects to new workout when next_path is workout" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 4)
    sign_in(@user)

    patch setup_path, params: { next_path: "workout" }
    assert_redirected_to new_workout_path
    @user.reload
    assert @user.setup_completed?
  end

  test "PATCH /setup complete step redirects to new routine when next_path is routine" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 4)
    sign_in(@user)

    patch setup_path, params: { next_path: "routine" }
    assert_redirected_to new_workout_routine_path
    @user.reload
    assert @user.setup_completed?
  end

  test "GET /setup for unauthenticated user with existing users redirects to login" do
    get setup_path
    assert_redirected_to new_session_path
  end

  test "PATCH /setup garmin step with valid credentials saves and advances" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 3)
    sign_in(@user)

    patch setup_path,
          params: {
            third_party_credential: {
              username: "garmin_user",
              password: "garmin_pass"
            }
          }
    assert_redirected_to setup_path
    @user.reload
    assert_equal 4, @user.wizard_step

    credential = @user.garmin_credential
    assert_equal "garmin_user", credential.username
  end

  test "PATCH /setup garmin step with invalid credentials returns 422" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 3)
    sign_in(@user)

    ThirdPartyCredential.any_instance.stubs(:save).returns(false)

    patch setup_path,
          params: {
            third_party_credential: {
              username: "",
              password: ""
            }
          }
    assert_response :unprocessable_entity
  end

  test "PATCH /setup account step for authenticated user with blank password skips password update" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 0)
    old_digest = @user.password_digest
    sign_in(@user)

    patch setup_path,
          params: {
            user: {
              first_name: "Changed",
              last_name: "Name",
              email_address: @user.email_address,
              password: "",
              password_confirmation: ""
            }
          }

    assert_redirected_to setup_path
    @user.reload
    assert_equal "Changed", @user.first_name
    assert_equal old_digest, @user.password_digest
  end

  test "PATCH /setup account step for authenticated user updates existing user" do
    @user = users(:john)
    @user.update!(setup_completed: false, wizard_step: 0)
    sign_in(@user)

    patch setup_path,
          params: {
            user: {
              first_name: "Updated",
              last_name: "Name",
              email_address: @user.email_address,
              password: "",
              password_confirmation: ""
            }
          }

    assert_redirected_to setup_path
    @user.reload
    assert_equal "Updated", @user.first_name
    assert_equal "Name", @user.last_name
    assert_equal 1, @user.wizard_step
  end
end
