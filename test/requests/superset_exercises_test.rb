require "test_helper"

class SupersetExercisesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @superset = supersets(:push_pull)
    @exercise = exercises(:squat)
    sign_in(@user)
  end

  test "GET /supersets/:superset_id/superset_exercises/new returns success" do
    get new_superset_superset_exercise_path(@superset)
    assert_response :success
  end

  test "POST /supersets/:superset_id/superset_exercises creates a new superset exercise with valid params" do
    assert_difference "SupersetExercise.count", 1 do
      post superset_superset_exercises_path(@superset),
           params: {
             superset_exercise: {
               exercise_id: @exercise.id
             }
           },
           as: :turbo_stream
    end
  end

  test "POST /supersets/:superset_id/superset_exercises sets position automatically" do
    post superset_superset_exercises_path(@superset),
         params: {
           superset_exercise: {
             exercise_id: @exercise.id
           }
         },
         as: :turbo_stream
    assert_equal 3, SupersetExercise.last.position
  end

  test "POST /supersets/:superset_id/superset_exercises returns unprocessable entity for duplicate exercise" do
    existing_exercise = @superset.exercises.first
    post superset_superset_exercises_path(@superset),
         params: {
           superset_exercise: {
             exercise_id: existing_exercise.id
           }
         },
         as: :turbo_stream
    assert_response :unprocessable_content
  end

  test "DELETE /supersets/:superset_id/superset_exercises/:id destroys the superset exercise" do
    superset_exercise = superset_exercises(:push_pull_bench)
    assert_difference "SupersetExercise.count", -1 do
      delete superset_superset_exercise_path(@superset, superset_exercise),
             as: :turbo_stream
    end
  end

  test "DELETE /supersets/:superset_id/superset_exercises/:id reorders remaining exercises" do
    superset_exercise = superset_exercises(:push_pull_bench)
    second_exercise = superset_exercises(:push_pull_pullup)
    delete superset_superset_exercise_path(@superset, superset_exercise),
           as: :turbo_stream
    assert_equal 1, second_exercise.reload.position
  end

  test "PATCH /supersets/:superset_id/superset_exercises/:id/move moves exercise to new position" do
    superset_exercise = superset_exercises(:push_pull_bench)
    patch move_superset_superset_exercise_path(@superset, superset_exercise),
          params: {
            position: 2
          }
    assert_equal 2, superset_exercise.reload.position
  end
end
