require "test_helper"

class WorkoutRoutineDayExercisesTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @workout_routine = workout_routines(:push_pull_legs)
    @workout_routine_day = workout_routine_days(:push_day)
    @exercise = exercises(:squat)
    @workout_routine_day_exercise =
      workout_routine_day_exercises(:push_day_bench)
    sign_in(@user)
  end

  test "GET new returns success" do
    get new_workout_routine_workout_routine_day_workout_routine_day_exercise_path(
          @workout_routine,
          @workout_routine_day
        )
    assert_response :success
  end

  test "POST create with valid params creates a new workout routine day exercise" do
    assert_difference "WorkoutRoutineDayExercise.count", 1 do
      post workout_routine_workout_routine_day_workout_routine_day_exercises_path(
             @workout_routine,
             @workout_routine_day
           ),
           params: {
             workout_routine_day_exercise: {
               exercise_id: @exercise.id,
               workout_routine_day_id: @workout_routine_day.id
             }
           },
           as: :turbo_stream
    end
  end

  test "POST create sets position automatically" do
    post workout_routine_workout_routine_day_workout_routine_day_exercises_path(
           @workout_routine,
           @workout_routine_day
         ),
         params: {
           workout_routine_day_exercise: {
             exercise_id: @exercise.id,
             workout_routine_day_id: @workout_routine_day.id
           }
         },
         as: :turbo_stream
    assert_equal 2, WorkoutRoutineDayExercise.last.position
  end

  test "POST create with invalid params renders new form" do
    post workout_routine_workout_routine_day_workout_routine_day_exercises_path(
           @workout_routine,
           @workout_routine_day
         ),
         params: {
           workout_routine_day_exercise: {
             exercise_id: nil,
             workout_routine_day_id: @workout_routine_day.id
           }
         },
         as: :turbo_stream
    assert_response :success
  end

  test "DELETE destroy destroys the workout routine day exercise" do
    assert_difference "WorkoutRoutineDayExercise.count", -1 do
      delete workout_routine_workout_routine_day_workout_routine_day_exercise_path(
               @workout_routine,
               @workout_routine_day,
               @workout_routine_day_exercise
             ),
             as: :turbo_stream
    end
  end

  test "GET comment_modal returns success" do
    get comment_modal_workout_routine_workout_routine_day_workout_routine_day_exercise_path(
          @workout_routine,
          @workout_routine_day,
          @workout_routine_day_exercise
        )
    assert_response :success
  end

  test "PATCH update_comment updates the comment" do
    patch update_comment_workout_routine_workout_routine_day_workout_routine_day_exercise_path(
            @workout_routine,
            @workout_routine_day,
            @workout_routine_day_exercise
          ),
          params: {
            workout_routine_day_exercise: {
              comment: "focus on form"
            }
          },
          as: :turbo_stream

    assert_response :success
    assert_equal "focus on form", @workout_routine_day_exercise.reload.comment
  end

  test "PATCH update_comment clears the comment when blank" do
    @workout_routine_day_exercise.update!(comment: "old comment")

    patch update_comment_workout_routine_workout_routine_day_workout_routine_day_exercise_path(
            @workout_routine,
            @workout_routine_day,
            @workout_routine_day_exercise
          ),
          params: {
            workout_routine_day_exercise: {
              comment: ""
            }
          },
          as: :turbo_stream

    assert_response :success
    assert_equal "", @workout_routine_day_exercise.reload.comment
  end

  test "PATCH move moves the exercise to a new position" do
    @workout_routine_day_exercise.update!(position: 1)
    second_exercise =
      WorkoutRoutineDayExercise.create!(
        workout_routine_day: @workout_routine_day,
        exercise: @exercise,
        position: 2
      )

    patch move_workout_routine_workout_routine_day_workout_routine_day_exercise_path(
            @workout_routine,
            @workout_routine_day,
            @workout_routine_day_exercise
          ),
          params: {
            position: 2
          }

    assert_response :ok
    assert_equal 2, @workout_routine_day_exercise.reload.position
  end
end
