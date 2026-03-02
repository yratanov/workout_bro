require "test_helper"

class WorkoutRoutinesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @workout_routine = workout_routines(:push_pull_legs)
    sign_in(@user)
  end

  test "GET /workout_routines returns success" do
    get workout_routines_path
    assert_response :success
  end

  test "GET /workout_routines shows user's workout routines" do
    get workout_routines_path
    assert_includes response.body, @workout_routine.name
  end

  test "GET /workout_routines/:id returns success" do
    get workout_routine_path(@workout_routine)
    assert_response :success
  end

  test "GET /workout_routines/:id shows workout routine details" do
    get workout_routine_path(@workout_routine)
    assert_includes response.body, @workout_routine.name
  end

  test "GET /workout_routines/new returns success" do
    get new_workout_routine_path
    assert_response :success
  end

  test "POST /workout_routines with valid params creates a new workout routine" do
    assert_difference "WorkoutRoutine.count", 1 do
      post workout_routines_path,
           params: {
             workout_routine: {
               name: "New Routine"
             }
           }
    end
  end

  test "POST /workout_routines with valid params redirects to the new routine" do
    post workout_routines_path,
         params: {
           workout_routine: {
             name: "New Routine"
           }
         }
    assert_redirected_to WorkoutRoutine.last
  end

  test "POST /workout_routines with invalid params returns unprocessable entity" do
    WorkoutRoutine.any_instance.stubs(:save).returns(false)
    post workout_routines_path, params: { workout_routine: { name: "Test" } }
    assert_response :unprocessable_content
  end

  test "DELETE /workout_routines/:id destroys the workout routine" do
    deletable_routine =
      @user.workout_routines.create!(name: "Deletable Routine")
    assert_difference "WorkoutRoutine.count", -1 do
      delete workout_routine_path(deletable_routine)
    end
  end

  test "DELETE /workout_routines/:id redirects to index" do
    deletable_routine =
      @user.workout_routines.create!(name: "Deletable Routine")
    delete workout_routine_path(deletable_routine)
    assert_redirected_to workout_routines_path
  end
end
