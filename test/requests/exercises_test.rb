require "test_helper"

class ExercisesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @exercise = exercises(:pull_up)
    @muscle = muscles(:chest)
    sign_in(@user)
  end

  test "GET /exercises returns success" do
    get exercises_path
    assert_response :success
  end

  test "GET /exercises shows user's exercises" do
    get exercises_path
    assert_includes response.body, @exercise.name
  end

  test "GET /exercises/:id returns success" do
    get exercise_path(@exercise)
    assert_response :success
  end

  test "GET /exercises/:id shows exercise details" do
    get exercise_path(@exercise)
    assert_includes response.body, @exercise.name
  end

  test "GET /exercises/new returns success" do
    get new_exercise_path
    assert_response :success
  end

  test "POST /exercises with valid params creates a new exercise" do
    assert_difference "Exercise.count", 1 do
      post exercises_path,
           params: {
             exercise: {
               name: "New Exercise",
               muscle_id: @muscle.id,
               with_weights: true,
               with_band: false
             }
           }
    end
  end

  test "POST /exercises with valid params redirects to the new exercise" do
    post exercises_path,
         params: {
           exercise: {
             name: "New Exercise",
             muscle_id: @muscle.id,
             with_weights: true,
             with_band: false
           }
         }
    assert_redirected_to Exercise.last
  end

  test "POST /exercises with invalid params returns unprocessable entity" do
    Exercise.any_instance.stubs(:save).returns(false)
    post exercises_path, params: { exercise: { name: "Test" } }
    assert_response :unprocessable_content
  end

  test "GET /exercises/:id/edit returns success" do
    get edit_exercise_path(@exercise)
    assert_response :success
  end

  test "PATCH /exercises/:id with valid params updates the exercise" do
    patch exercise_path(@exercise),
          params: {
            exercise: {
              name: "Updated Name"
            }
          }
    assert_equal "Updated Name", @exercise.reload.name
  end

  test "PATCH /exercises/:id with valid params redirects to the exercise" do
    patch exercise_path(@exercise),
          params: {
            exercise: {
              name: "Updated Name"
            }
          }
    assert_redirected_to @exercise
  end

  test "PATCH /exercises/:id with invalid params returns unprocessable entity" do
    Exercise.any_instance.stubs(:update).returns(false)
    patch exercise_path(@exercise), params: { exercise: { name: "Test" } }
    assert_response :unprocessable_content
  end

  test "DELETE /exercises/:id destroys the exercise" do
    deletable_exercise =
      @user.exercises.create!(name: "Deletable Exercise", muscle: @muscle)
    assert_difference "Exercise.count", -1 do
      delete exercise_path(deletable_exercise)
    end
  end

  test "DELETE /exercises/:id redirects to index" do
    deletable_exercise =
      @user.exercises.create!(name: "Deletable Exercise", muscle: @muscle)
    delete exercise_path(deletable_exercise)
    assert_redirected_to exercises_path
  end
end
