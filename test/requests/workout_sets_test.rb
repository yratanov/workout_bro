require "test_helper"

class WorkoutSetsTest < ActionDispatch::IntegrationTest
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

  test "GET /workout_sets/:id/notes_modal returns the notes modal" do
    get notes_modal_workout_set_path(@workout_set)
    assert_response :success
    assert_includes response.body, "Notes for"
    assert_includes response.body, "Bench Press"
  end

  test "PATCH /workout_sets/:id/update_notes updates the workout set notes" do
    patch update_notes_workout_set_path(@workout_set),
          params: {
            workout_set: {
              notes: "Good form on this set"
            }
          }
    @workout_set.reload
    assert_equal "Good form on this set", @workout_set.notes
  end

  test "PATCH /workout_sets/:id/update_notes returns turbo stream response" do
    patch update_notes_workout_set_path(@workout_set),
          params: {
            workout_set: {
              notes: "Test notes"
            }
          },
          headers: {
            "Accept" => "text/vnd.turbo-stream.html"
          }
    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "GET /workout_sets/new returns success" do
    get new_workout_set_path(workout_id: @workout.id)
    assert_response :success
  end

  test "POST /workout_sets creates a workout set" do
    assert_difference "WorkoutSet.count", 1 do
      post workout_sets_path,
           params: {
             workout_set: {
               workout_id: @workout.id,
               exercise_id: exercises(:squat).id
             }
           },
           headers: {
             "Accept" => "text/vnd.turbo-stream.html"
           }
    end

    assert_response :success

    workout_set = WorkoutSet.last
    assert_equal @workout.id, workout_set.workout_id
    assert_equal exercises(:squat).id, workout_set.exercise_id
    assert workout_set.started_at.present?
  end

  test "POST /workout_sets returns turbo stream response" do
    post workout_sets_path,
         params: {
           workout_set: {
             workout_id: @workout.id,
             exercise_id: exercises(:squat).id
           }
         },
         headers: {
           "Accept" => "text/vnd.turbo-stream.html"
         }

    assert_equal "text/vnd.turbo-stream.html", response.media_type
  end

  test "POST /workout_sets/:id/stop ends a workout set" do
    assert_nil @workout_set.ended_at

    post stop_workout_set_path(@workout_set),
         headers: {
           "Accept" => "text/vnd.turbo-stream.html"
         }

    @workout_set.reload
    assert @workout_set.ended_at.present?
  end

  test "POST /workout_sets/:id/stop for superset set ends all sibling sets" do
    superset = supersets(:push_pull)
    set1 =
      @workout.workout_sets.create!(
        exercise: exercises(:bench_press),
        superset: superset,
        superset_group: 1,
        started_at: 10.minutes.ago
      )
    set2 =
      @workout.workout_sets.create!(
        exercise: exercises(:pull_up),
        superset: superset,
        superset_group: 1,
        started_at: 10.minutes.ago
      )

    post stop_workout_set_path(set1),
         headers: {
           "Accept" => "text/vnd.turbo-stream.html"
         }

    set1.reload
    set2.reload
    assert set1.ended_at.present?
    assert set2.ended_at.present?
  end

  test "POST /workout_sets/:id/reopen clears ended_at" do
    @workout_set.update!(ended_at: 5.minutes.ago)

    post reopen_workout_set_path(@workout_set),
         headers: {
           "Accept" => "text/vnd.turbo-stream.html"
         }

    @workout_set.reload
    assert_nil @workout_set.ended_at
  end

  test "GET /workout_sets/:id/previous_history returns success" do
    get previous_history_workout_set_path(@workout_set)
    assert_response :success
  end

  test "DELETE /workout_sets/:id removes the workout set" do
    assert_difference "WorkoutSet.count", -1 do
      delete workout_set_path(@workout_set),
             headers: {
               "Accept" => "text/vnd.turbo-stream.html"
             }
    end

    assert_response :success
  end

  test "POST /workout_sets/start_superset creates workout sets for all exercises in superset" do
    superset = supersets(:push_pull)

    assert_difference "WorkoutSet.count", 2 do
      post start_superset_workout_sets_path,
           params: {
             workout_id: @workout.id,
             superset_id: superset.id
           },
           headers: {
             "Accept" => "text/vnd.turbo-stream.html"
           }
    end

    assert_response :success

    created_sets =
      @workout.workout_sets.where(superset: superset).order(:created_at).last(2)
    assert_equal exercises(:bench_press).id, created_sets[0].exercise_id
    assert_equal exercises(:pull_up).id, created_sets[1].exercise_id
    assert created_sets.all? { |s| s.started_at.present? }
    assert created_sets.all? { |s| s.superset_group.present? }
    assert_equal created_sets[0].superset_group, created_sets[1].superset_group
  end
end
