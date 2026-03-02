require "test_helper"

class PersonalRecordsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
  end

  test "GET /personal_records returns success" do
    get personal_records_path
    assert_response :success
  end

  test "GET /personal_records displays personal records" do
    get personal_records_path
    assert_includes response.body, "Personal Records"
  end

  test "GET /personal_records shows empty state message when no personal records" do
    @user.personal_records.destroy_all
    get personal_records_path
    assert_includes response.body, "No personal records yet"
  end

  test "GET /personal_records displays PR exercise name" do
    get personal_records_path
    assert_includes response.body, "Bench Press"
  end

  test "GET /personal_records displays PR type badge" do
    get personal_records_path
    assert_includes response.body, "Max Weight"
  end

  test "GET /personal_records groups PRs by date" do
    get personal_records_path
    pr = personal_records(:bench_press_max_weight)
    assert_includes response.body, I18n.l(pr.achieved_on, format: :long)
  end

  test "GET /personal_records displays band badge for banded PRs" do
    banded_squat = exercises(:banded_squat)
    workout = workouts(:completed_workout)
    rep =
      workout
        .workout_sets
        .create!(exercise: banded_squat, started_at: 1.hour.ago)
        .workout_reps
        .create!(reps: 15, band: "heavy")

    @user.personal_records.create!(
      exercise: banded_squat,
      workout: workout,
      workout_rep: rep,
      pr_type: :max_reps,
      reps: 15,
      band: "heavy",
      achieved_on: Date.today
    )

    get personal_records_path
    assert_includes response.body, "Heavy Band"
  end

  test "GET /personal_records displays run PRs" do
    run_workout =
      @user.workouts.create!(
        workout_type: :run,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        distance: 5000
      )
    @user.personal_records.create!(
      workout: run_workout,
      pr_type: :longest_distance,
      distance: 5000,
      achieved_on: Date.today
    )
    @user.personal_records.create!(
      workout: run_workout,
      pr_type: :fastest_pace,
      distance: 5000,
      pace: 360.0,
      achieved_on: Date.today
    )

    get personal_records_path
    assert_includes response.body, "Run"
  end

  test "GET /personal_records displays longest distance PR" do
    run_workout =
      @user.workouts.create!(
        workout_type: :run,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        distance: 5000
      )
    @user.personal_records.create!(
      workout: run_workout,
      pr_type: :longest_distance,
      distance: 5000,
      achieved_on: Date.today
    )

    get personal_records_path
    assert_includes response.body, "Longest Distance"
    assert_includes response.body, "5.0 km"
  end

  test "GET /personal_records displays fastest pace PR" do
    run_workout =
      @user.workouts.create!(
        workout_type: :run,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        distance: 5000
      )
    @user.personal_records.create!(
      workout: run_workout,
      pr_type: :fastest_pace,
      distance: 5000,
      pace: 360.0,
      achieved_on: Date.today
    )

    get personal_records_path
    assert_includes response.body, "Fastest Pace"
    assert_includes response.body, "6:00"
  end
end
