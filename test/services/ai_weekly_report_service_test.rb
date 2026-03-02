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

  test "calls generate_chat with conversation messages when trainer is configured" do
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |messages, **opts|
        messages.is_a?(Array) &&
          opts[:system_instruction].include?("A motivational trainer.") &&
          messages.last[:role] == "user" &&
          messages.last[:text].include?("Training Week") &&
          messages.last[:text].include?("weekly overview")
      end
      .returns("Weekly report")

    result = AiWeeklyReportService.new(@user, @week_start).call
    assert_equal "Weekly report", result
  end

  test "falls back to generate for unconfigured trainer" do
    @ai_trainer.update!(status: :pending)

    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client.expects(:generate).returns("Basic report")

    result = AiWeeklyReportService.new(@user, @week_start).call
    assert_equal "Basic report", result
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

    captured_message = nil
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |messages, **_opts|
        captured_message = messages.last[:text]
        true
      end
      .returns("Report")

    AiWeeklyReportService.new(@user, @week_start).call

    assert_includes captured_message, "Bench Press"
    assert_includes captured_message, "80.0kg x 8"
    assert_includes captured_message, "Strength"
  end

  test "includes no completed workouts message when no workouts exist in range" do
    @user.workouts.update_all(ended_at: nil)

    captured_message = nil
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |messages, **_opts|
        captured_message = messages.last[:text]
        true
      end
      .returns("Report")

    AiWeeklyReportService.new(@user, @week_start).call

    assert_includes captured_message, "No completed workouts"
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

    captured_message = nil
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |messages, **_opts|
        captured_message = messages.last[:text]
        true
      end
      .returns("Report")

    AiWeeklyReportService.new(@user, @week_start).call

    assert_includes captured_message, "Personal Records"
    assert_includes captured_message, "Squat"
    assert_includes captured_message, "Max weight"
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

    captured_message = nil
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |messages, **_opts|
        captured_message = messages.last[:text]
        true
      end
      .returns("Report")

    AiWeeklyReportService.new(@user, @week_start).call

    assert_includes captured_message, "Run"
    assert_includes captured_message, "Distance"
    assert_includes captured_message, "5.0km"
  end

  test "uses Russian locale instruction when user locale is ru" do
    @user.update!(locale: "ru")

    captured_message = nil
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |messages, **_opts|
        captured_message = messages.last[:text]
        true
      end
      .returns("Report")

    AiWeeklyReportService.new(@user, @week_start).call

    assert_includes captured_message, "Russian"
    refute_includes captured_message, "English"
  end

  test "uses English locale instruction when user locale is en" do
    @user.update!(locale: "en")

    captured_message = nil
    mock_client = mock("AiClient")
    AiClient.stubs(:for).returns(mock_client)
    mock_client
      .expects(:generate_chat)
      .with do |messages, **_opts|
        captured_message = messages.last[:text]
        true
      end
      .returns("Report")

    AiWeeklyReportService.new(@user, @week_start).call

    assert_includes captured_message, "English"
    refute_includes captured_message, "Russian"
  end
end
