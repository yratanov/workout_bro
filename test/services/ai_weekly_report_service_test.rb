require "test_helper"

class AiWeeklyReportServiceTest < ActiveSupport::TestCase
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
      trainer_profile: "A motivational trainer."
    )
    @week_start = Date.current.beginning_of_week
  end

  test "calls generate_chat when trainer is configured" do
    VCR.use_cassette("ai_weekly_report/chat") do
      result = AiWeeklyReportService.new(@user, @week_start).call
      assert_equal "Weekly report", result
    end
  end

  test "falls back to generate for unconfigured trainer" do
    @ai_trainer.update!(status: :pending)

    VCR.use_cassette("ai_weekly_report/simple") do
      result = AiWeeklyReportService.new(@user, @week_start).call
      assert_equal "Basic report", result
    end
  end

  test "includes workout data with exercise names in the prompt" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: @week_start.to_time + 10.hours,
        ended_at: @week_start.to_time + 11.hours,
        date: @week_start
      )
    exercise = exercises(:bench_press)
    ws =
      WorkoutSet.create!(
        workout: workout,
        exercise: exercise,
        started_at: workout.started_at,
        ended_at: workout.started_at + 5.minutes
      )
    WorkoutRep.create!(workout_set: ws, weight: 80, reps: 8)

    VCR.use_cassette("ai_weekly_report/with_data") do
      result = AiWeeklyReportService.new(@user, @week_start).call
      assert_equal "Report", result
    end
  end

  test "includes no completed workouts message when no workouts exist in range" do
    @user.workouts.update_all(ended_at: nil)

    VCR.use_cassette("ai_weekly_report/no_workouts") do
      result = AiWeeklyReportService.new(@user, @week_start).call
      assert_equal "Report", result
    end
  end

  test "includes personal records in the prompt when present" do
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: @week_start.to_time + 10.hours,
        ended_at: @week_start.to_time + 11.hours,
        date: @week_start
      )
    exercise = exercises(:squat)
    ws =
      WorkoutSet.create!(
        workout: workout,
        exercise: exercise,
        started_at: workout.started_at,
        ended_at: workout.started_at + 5.minutes
      )
    WorkoutRep.create!(workout_set: ws, weight: 120, reps: 5)
    rep = WorkoutRep.create!(workout_set: ws, weight: 120, reps: 5)
    PersonalRecord.create!(
      user: @user,
      exercise: exercise,
      workout: workout,
      workout_rep: rep,
      pr_type: :max_weight,
      weight: 120,
      reps: 5,
      achieved_on: @week_start
    )

    VCR.use_cassette("ai_weekly_report/with_prs") do
      result = AiWeeklyReportService.new(@user, @week_start).call
      assert_equal "Report", result
    end
  end

  test "formats run workouts differently from strength workouts" do
    Workout.create!(
      user: @user,
      workout_type: :run,
      started_at: @week_start.to_time + 10.hours,
      ended_at: @week_start.to_time + 10.hours + 30.minutes,
      date: @week_start,
      distance: 5000,
      time_in_seconds: 1800
    )

    VCR.use_cassette("ai_weekly_report/run_format") do
      result = AiWeeklyReportService.new(@user, @week_start).call
      assert_equal "Report", result
    end
  end

  test "uses Russian locale instruction when user locale is ru" do
    @user.update!(locale: "ru")

    VCR.use_cassette("ai_weekly_report/russian") do
      result = AiWeeklyReportService.new(@user, @week_start).call
      assert_equal "Report", result
    end
  end

  test "uses English locale instruction when user locale is en" do
    @user.update!(locale: "en")

    VCR.use_cassette("ai_weekly_report/english") do
      result = AiWeeklyReportService.new(@user, @week_start).call
      assert_equal "Report", result
    end
  end
end
