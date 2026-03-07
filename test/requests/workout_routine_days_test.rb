require "test_helper"

class WorkoutRoutineDaysTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @workout_routine = workout_routines(:push_pull_legs)
    @workout_routine_day = workout_routine_days(:push_day)
    sign_in(@user)
  end

  test "GET /workout_routines/:workout_routine_id/workout_routine_days returns success" do
    get workout_routine_workout_routine_days_path(@workout_routine),
        as: :turbo_stream
    assert_response :success
  end

  test "GET /workout_routines/:workout_routine_id/workout_routine_days/new returns success" do
    get new_workout_routine_workout_routine_day_path(@workout_routine)
    assert_response :success
  end

  test "POST /workout_routines/:workout_routine_id/workout_routine_days creates a new day with valid params" do
    assert_difference "WorkoutRoutineDay.count", 1 do
      post workout_routine_workout_routine_days_path(@workout_routine),
           params: {
             workout_routine_day: {
               name: "New Day"
             }
           }
    end
  end

  test "POST /workout_routines/:workout_routine_id/workout_routine_days saves notes" do
    post workout_routine_workout_routine_days_path(@workout_routine),
         params: {
           workout_routine_day: {
             name: "Day With Notes",
             notes: "Focus on compound movements"
           }
         }
    day = WorkoutRoutineDay.last
    assert_equal "Day With Notes", day.name
    assert_equal "Focus on compound movements", day.notes
  end

  test "POST /workout_routines/:workout_routine_id/workout_routine_days redirects to edit page" do
    post workout_routine_workout_routine_days_path(@workout_routine),
         params: {
           workout_routine_day: {
             name: "New Day"
           }
         }
    assert_redirected_to edit_workout_routine_workout_routine_day_path(
                           @workout_routine,
                           WorkoutRoutineDay.last
                         )
  end

  test "POST /workout_routines/:workout_routine_id/workout_routine_days with invalid params renders new form" do
    post workout_routine_workout_routine_days_path(@workout_routine),
         params: {
           workout_routine_day: {
             name: ""
           }
         }
    assert_response :success
  end

  test "GET /workout_routines/:workout_routine_id/workout_routine_days/:id/edit returns success" do
    get edit_workout_routine_workout_routine_day_path(
          @workout_routine,
          @workout_routine_day
        )
    assert_response :success
  end

  test "PATCH /workout_routines/:workout_routine_id/workout_routine_days/:id updates the day with valid params" do
    patch workout_routine_workout_routine_day_path(
            @workout_routine,
            @workout_routine_day
          ),
          params: {
            workout_routine_day: {
              name: "Updated Day"
            }
          }
    assert_equal "Updated Day", @workout_routine_day.reload.name
  end

  test "PATCH /workout_routines/:workout_routine_id/workout_routine_days/:id updates notes" do
    patch workout_routine_workout_routine_day_path(
            @workout_routine,
            @workout_routine_day
          ),
          params: {
            workout_routine_day: {
              name: @workout_routine_day.name,
              notes: "Updated notes"
            }
          }
    assert_equal "Updated notes", @workout_routine_day.reload.notes
  end

  test "PATCH /workout_routines/:workout_routine_id/workout_routine_days/:id redirects to workout routine" do
    patch workout_routine_workout_routine_day_path(
            @workout_routine,
            @workout_routine_day
          ),
          params: {
            workout_routine_day: {
              name: "Updated Day"
            }
          }
    assert_redirected_to workout_routine_path(@workout_routine)
  end

  test "PATCH /workout_routines/:workout_routine_id/workout_routine_days/:id with invalid params renders edit form" do
    patch workout_routine_workout_routine_day_path(
            @workout_routine,
            @workout_routine_day
          ),
          params: {
            workout_routine_day: {
              name: ""
            }
          }
    assert_response :success
  end
end
