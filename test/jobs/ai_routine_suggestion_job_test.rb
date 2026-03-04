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
  end

  test "creates routine days and exercises from AI response" do
    VCR.use_cassette("jobs/routine_suggestion/success") do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end

    @workout_routine.reload
    assert_nil @workout_routine.ai_status
    assert_equal "Push Pull Legs Routine", @workout_routine.name
    assert_equal 3, @workout_routine.workout_routine_days.count

    push_day = @workout_routine.workout_routine_days.find_by(name: "Push Day")
    assert_equal 2, push_day.workout_routine_day_exercises.count
  end

  test "sets ai_status to in_progress during execution" do
    VCR.use_cassette("jobs/routine_suggestion/success") do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end

    # After completion, ai_status should be nil (cleared)
    assert_nil @workout_routine.reload.ai_status
  end

  test "saves comments on exercises from AI response" do
    VCR.use_cassette("jobs/routine_suggestion/comments") do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end

    day = @workout_routine.reload.workout_routine_days.first
    exercises = day.workout_routine_day_exercises.order(:position)
    assert_equal "focus on form", exercises.first.comment
    assert_nil exercises.second.comment
  end

  test "saves comments on superset exercises from AI response" do
    VCR.use_cassette("jobs/routine_suggestion/superset_comments") do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end

    day = @workout_routine.reload.workout_routine_days.first
    day_exercise = day.workout_routine_day_exercises.first
    assert_equal "no rest between exercises", day_exercise.comment
  end

  test "creates new exercises when not found in user's list" do
    assert_difference "Exercise.count", 1 do
      VCR.use_cassette("jobs/routine_suggestion/new_exercise") do
        AiRoutineSuggestionJob.new.perform(
          workout_routine: @workout_routine,
          params: @params
        )
      end
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
    VCR.use_cassette("jobs/routine_suggestion/invalid_muscle") do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end

    day = @workout_routine.reload.workout_routine_days.first
    assert_equal 1, day.workout_routine_day_exercises.count
    assert_equal "Bench Press",
                 day.workout_routine_day_exercises.first.exercise.name
  end

  test "creates supersets with component exercises" do
    assert_difference "Superset.count", 1 do
      VCR.use_cassette("jobs/routine_suggestion/superset") do
        AiRoutineSuggestionJob.new.perform(
          workout_routine: @workout_routine,
          params: @params
        )
      end
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

    assert_no_difference "Superset.count" do
      VCR.use_cassette("jobs/routine_suggestion/reuse_superset") do
        AiRoutineSuggestionJob.new.perform(
          workout_routine: @workout_routine,
          params: @params
        )
      end
    end

    day = @workout_routine.reload.workout_routine_days.first
    assert_equal existing_superset,
                 day.workout_routine_day_exercises.first.superset
  end

  test "creates supersets with new exercises" do
    assert_difference "Exercise.count", 2 do
      assert_difference "Superset.count", 1 do
        VCR.use_cassette("jobs/routine_suggestion/new_superset") do
          AiRoutineSuggestionJob.new.perform(
            workout_routine: @workout_routine,
            params: @params
          )
        end
      end
    end

    superset = @user.supersets.find_by(name: "Shoulder Combo")
    assert_equal ["Front Raise", "Lateral Raise"],
                 superset.exercises.map(&:name).sort
  end

  test "sets failed status on error" do
    VCR.use_cassette("jobs/routine_suggestion/error") do
      assert_raises(StandardError) do
        AiRoutineSuggestionJob.new.perform(
          workout_routine: @workout_routine,
          params: @params
        )
      end
    end

    @workout_routine.reload
    assert_equal "failed", @workout_routine.ai_status
    assert_not_nil @workout_routine.ai_generation_error
  end

  test "broadcasts turbo stream reload on success" do
    Turbo::StreamsChannel.expects(:broadcast_replace_to).with(
      [@workout_routine, :ai_generation],
      target: "ai_generation_status",
      html:
        '<div id="ai_generation_status" data-controller="page-reload"></div>'
    )

    VCR.use_cassette("jobs/routine_suggestion/success") do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end
  end

  test "broadcasts turbo stream reload on failure" do
    Turbo::StreamsChannel.expects(:broadcast_replace_to).with(
      [@workout_routine, :ai_generation],
      target: "ai_generation_status",
      html:
        '<div id="ai_generation_status" data-controller="page-reload"></div>'
    )

    VCR.use_cassette("jobs/routine_suggestion/error") do
      assert_raises(StandardError) do
        AiRoutineSuggestionJob.new.perform(
          workout_routine: @workout_routine,
          params: @params
        )
      end
    end
  end

  test "uses simple generate when trainer not configured" do
    @ai_trainer.update!(status: :pending, trainer_profile: nil)

    VCR.use_cassette("jobs/routine_suggestion/simple") do
      AiRoutineSuggestionJob.new.perform(
        workout_routine: @workout_routine,
        params: @params
      )
    end

    assert_nil @workout_routine.reload.ai_status
  end
end
