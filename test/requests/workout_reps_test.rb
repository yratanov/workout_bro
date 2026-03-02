require "test_helper"

class WorkoutRepsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
    @workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        workout_routine_day: workout_routine_days(:push_day)
      )
    @workout_set =
      @workout.workout_sets.create!(
        exercise: exercises(:bench_press),
        started_at: 30.minutes.ago
      )
  end

  test "POST /workout_reps creates a workout rep" do
    assert_difference "WorkoutRep.count", 1 do
      post workout_reps_path,
           params: {
             workout_rep: {
               workout_set_id: @workout_set.id,
               weight: 80,
               reps: 10
             }
           },
           headers: {
             "Accept" => "text/vnd.turbo-stream.html"
           }
    end

    assert_response :success

    rep = WorkoutRep.last
    assert_equal 80, rep.weight
    assert_equal 10, rep.reps
    assert_equal @workout_set.id, rep.workout_set_id
  end

  test "POST /workout_reps returns turbo stream response" do
    post workout_reps_path,
         params: {
           workout_rep: {
             workout_set_id: @workout_set.id,
             weight: 60,
             reps: 8
           }
         },
         headers: {
           "Accept" => "text/vnd.turbo-stream.html"
         }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "POST /workout_reps with band saves band value" do
    post workout_reps_path,
         params: {
           workout_rep: {
             workout_set_id: @workout_set.id,
             weight: 0,
             reps: 12,
             band: "heavy"
           }
         },
         headers: {
           "Accept" => "text/vnd.turbo-stream.html"
         }

    assert_response :success

    rep = WorkoutRep.last
    assert_equal "heavy", rep.band
  end

  test "POST /workout_reps with blank band saves nil" do
    post workout_reps_path,
         params: {
           workout_rep: {
             workout_set_id: @workout_set.id,
             weight: 60,
             reps: 10,
             band: ""
           }
         },
         headers: {
           "Accept" => "text/vnd.turbo-stream.html"
         }

    assert_response :success

    rep = WorkoutRep.last
    assert_nil rep.band
  end

  test "DELETE /workout_reps/:id removes the workout rep" do
    rep = @workout_set.workout_reps.create!(weight: 60, reps: 10)

    assert_difference "WorkoutRep.count", -1 do
      delete workout_rep_path(rep),
             headers: {
               "Accept" => "text/vnd.turbo-stream.html"
             }
    end

    assert_response :success
  end

  test "DELETE /workout_reps/:id returns turbo stream response" do
    rep = @workout_set.workout_reps.create!(weight: 60, reps: 10)

    delete workout_rep_path(rep),
           headers: {
             "Accept" => "text/vnd.turbo-stream.html"
           }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end
end
