require "test_helper"

class AiRoutineSuggestionJobTest < ActiveJob::TestCase
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )

    @ai_trainer = @user.ai_trainer
    @ai_trainer.update!(
      status: :completed,
      trainer_profile: "A balanced fitness trainer."
    )

    @workout_routine =
      @user.workout_routines.create!(
        name: "AI Routine (generating...)",
        ai_status: :pending
      )

    @params = {
      frequency: "3",
      split_type: "Push/Pull/Legs",
      experience_level: "Intermediate",
      focus_areas: [],
      additional_context: ""
    }

    @ai_response = {
      name: "Push Pull Legs Routine",
      days: [
        {
          name: "Push Day",
          exercises: [
            { name: "Bench Press", muscle: "chest" },
            { name: "Tricep Extension", muscle: "triceps" }
          ]
        },
        {
          name: "Pull Day",
          exercises: [
            { name: "Deadlift", muscle: "back" },
            { name: "Pull-Up", muscle: "back" },
            { name: "Bicep Curl", muscle: "biceps" }
          ]
        },
        { name: "Leg Day", exercises: [{ name: "Squat", muscle: "legs" }] }
      ]
    }.to_json

    @mock_client = mock("ai_client")
    AiClient.stubs(:for).returns(@mock_client)
  end

  test "creates routine days and exercises from AI response" do
    @mock_client.stubs(:generate_chat).returns(@ai_response)

    AiRoutineSuggestionJob.new.perform(
      workout_routine: @workout_routine,
      params: @params
    )

    @workout_routine.reload
    assert_nil @workout_routine.ai_status
    assert_equal "Push Pull Legs Routine", @workout_routine.name
    assert_equal 3, @workout_routine.workout_routine_days.count

    push_day = @workout_routine.workout_routine_days.find_by(name: "Push Day")
    assert_equal 2, push_day.workout_routine_day_exercises.count
  end

  test "sets ai_status to in_progress during execution" do
    @mock_client
      .stubs(:generate_chat)
      .with do
        assert_equal "in_progress", @workout_routine.reload.ai_status
        true
      end
      .returns(@ai_response)

    AiRoutineSuggestionJob.new.perform(
      workout_routine: @workout_routine,
      params: @params
    )
  end

  test "saves comments on exercises from AI response" do
    response = {
      name: "Commented Routine",
      days: [
        {
          name: "Day 1",
          exercises: [
            { name: "Bench Press", muscle: "chest", comment: "focus on form" },
            { name: "Squat", muscle: "legs" }
          ]
        }
      ]
    }.to_json

    @mock_client.stubs(:generate_chat).returns(response)

    AiRoutineSuggestionJob.new.perform(
      workout_routine: @workout_routine,
      params: @params
    )

    day = @workout_routine.reload.workout_routine_days.first
    exercises = day.workout_routine_day_exercises.order(:position)
    assert_equal "focus on form", exercises.first.comment
    assert_nil exercises.second.comment
  end

  test "saves comments on superset exercises from AI response" do
    response = {
      name: "Superset Comment Routine",
      days: [
        {
          name: "Day 1",
          exercises: [
            {
              superset: "Chest/Back Superset",
              comment: "no rest between exercises",
              exercises: [
                { name: "Bench Press", muscle: "chest" },
                { name: "Deadlift", muscle: "back" }
              ]
            }
          ]
        }
      ]
    }.to_json

    @mock_client.stubs(:generate_chat).returns(response)

    AiRoutineSuggestionJob.new.perform(
      workout_routine: @workout_routine,
      params: @params
    )

    day = @workout_routine.reload.workout_routine_days.first
    day_exercise = day.workout_routine_day_exercises.first
    assert_equal "no rest between exercises", day_exercise.comment
  end

  test "creates new exercises when not found in user's list" do
    response = {
      name: "Test Routine",
      days: [
        {
          name: "Day 1",
          exercises: [{ name: "Overhead Press", muscle: "shoulders" }]
        }
      ]
    }.to_json

    @mock_client.stubs(:generate_chat).returns(response)

    assert_difference "Exercise.count", 1 do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end

    new_exercise = @user.exercises.find_by(name: "Overhead Press")
    assert new_exercise.present?
    assert_equal "shoulders", new_exercise.muscle.name
    assert new_exercise.with_weights

    day = @workout_routine.reload.workout_routine_days.first
    assert_equal 1, day.workout_routine_day_exercises.count
    assert_equal new_exercise, day.workout_routine_day_exercises.first.exercise
  end

  test "skips exercises with invalid muscle group" do
    response = {
      name: "Test Routine",
      days: [
        {
          name: "Day 1",
          exercises: [
            { name: "Bench Press", muscle: "chest" },
            { name: "Magic Lift", muscle: "nonexistent_muscle" }
          ]
        }
      ]
    }.to_json

    @mock_client.stubs(:generate_chat).returns(response)

    AiRoutineSuggestionJob.new.perform(
      workout_routine: @workout_routine,
      params: @params
    )

    day = @workout_routine.reload.workout_routine_days.first
    assert_equal 1, day.workout_routine_day_exercises.count
    assert_equal "Bench Press",
                 day.workout_routine_day_exercises.first.exercise.name
  end

  test "creates supersets with component exercises" do
    response = {
      name: "Superset Routine",
      days: [
        {
          name: "Day 1",
          exercises: [
            {
              superset: "Chest/Back Superset",
              exercises: [
                { name: "Bench Press", muscle: "chest" },
                { name: "Deadlift", muscle: "back" }
              ]
            }
          ]
        }
      ]
    }.to_json

    @mock_client.stubs(:generate_chat).returns(response)

    assert_difference "Superset.count", 1 do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end

    superset = @user.supersets.find_by(name: "Chest/Back Superset")
    assert superset.present?
    assert_equal ["Bench Press", "Deadlift"].sort,
                 superset.exercises.map(&:name).sort

    day = @workout_routine.reload.workout_routine_days.first
    day_exercise = day.workout_routine_day_exercises.first
    assert_equal superset, day_exercise.superset
    assert_nil day_exercise.exercise
  end

  test "reuses existing supersets by name" do
    existing_superset = supersets(:push_pull)

    response = {
      name: "Reuse Routine",
      days: [
        {
          name: "Day 1",
          exercises: [
            {
              superset: "Push Pull",
              exercises: [
                { name: "Bench Press", muscle: "chest" },
                { name: "Pull-Up", muscle: "back" }
              ]
            }
          ]
        }
      ]
    }.to_json

    @mock_client.stubs(:generate_chat).returns(response)

    assert_no_difference "Superset.count" do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end

    day = @workout_routine.reload.workout_routine_days.first
    assert_equal existing_superset,
                 day.workout_routine_day_exercises.first.superset
  end

  test "creates supersets with new exercises" do
    response = {
      name: "New Superset Routine",
      days: [
        {
          name: "Day 1",
          exercises: [
            {
              superset: "Shoulder Combo",
              exercises: [
                { name: "Lateral Raise", muscle: "shoulders" },
                { name: "Front Raise", muscle: "shoulders" }
              ]
            }
          ]
        }
      ]
    }.to_json

    @mock_client.stubs(:generate_chat).returns(response)

    assert_difference "Exercise.count", 2 do
      assert_difference "Superset.count", 1 do
        AiRoutineSuggestionJob.new.perform(
          workout_routine: @workout_routine,
          params: @params
        )
      end
    end

    superset = @user.supersets.find_by(name: "Shoulder Combo")
    assert_equal ["Front Raise", "Lateral Raise"],
                 superset.exercises.map(&:name).sort
  end

  test "sets failed status on error" do
    @mock_client.stubs(:generate_chat).raises(StandardError.new("API error"))

    assert_raises(StandardError) do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end

    @workout_routine.reload
    assert_equal "failed", @workout_routine.ai_status
    assert_equal "API error", @workout_routine.ai_generation_error
  end

  test "uses simple generate when trainer not configured" do
    @ai_trainer.update!(status: :pending, trainer_profile: nil)
    @mock_client.expects(:generate).returns(@ai_response)

    AiRoutineSuggestionJob.new.perform(
      workout_routine: @workout_routine,
      params: @params
    )

    assert_nil @workout_routine.reload.ai_status
  end
end
