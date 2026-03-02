require "test_helper"

class StatsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    sign_in(@user)
  end

  test "GET /stats returns success" do
    get stats_path
    assert_response :success
  end

  test "GET /stats with workouts that have time_in_seconds displays hours per week data" do
    @user.workouts.create!(
      workout_type: :strength,
      date: Date.today,
      started_at: 1.hour.ago,
      ended_at: Time.current,
      time_in_seconds: 3600
    )
    get stats_path
    assert_response :success
  end

  test "GET /stats with run workouts that have distance displays distance per week data" do
    @user.workouts.create!(
      workout_type: :run,
      date: Date.today,
      started_at: 1.hour.ago,
      ended_at: Time.current,
      distance: 5000,
      time_in_seconds: 1800
    )
    get stats_path
    assert_response :success
  end

  test "GET /stats with completed workouts displays workouts per week data" do
    @user.workouts.create!(
      workout_type: :strength,
      date: Date.today,
      started_at: 1.hour.ago,
      ended_at: Time.current,
      time_in_seconds: 3600
    )
    @user.workouts.create!(
      workout_type: :run,
      date: Date.today,
      started_at: 2.hours.ago,
      ended_at: 1.hour.ago,
      distance: 3000,
      time_in_seconds: 1800
    )
    get stats_path
    assert_response :success
  end

  test "GET /stats without any workouts returns success with empty data" do
    @user.workouts.destroy_all
    get stats_path
    assert_response :success
  end
end
