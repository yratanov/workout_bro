require "application_system_test_case"

class WorkoutsTest < ApplicationSystemTestCase
  setup do
    @user = users(:john)
    login_as(@user)
  end

  # --- Viewing workouts ---

  test "shows the workouts index page" do
    assert_text "Workouts"
    assert_link "Start workout"
    workouts(:completed_workout, :active_workout).each(&:destroy)
  end

  # --- Starting a strength workout ---

  test "allows starting a new workout with default routine" do
    click_link "Start workout"

    assert_text "New Workout"
    # Default routine is Upper Lower with Upper Day pre-selected
    click_button "Start Workout"

    assert_text "Upper Lower"
    assert_text "Upper Day"
    assert_button "Finish"
  end

  # --- Completing a workout ---

  test "allows finishing an active workout and shows summary" do
    click_link "Start workout"
    click_button "Start Workout"

    accept_confirm { click_button "Finish" }

    # After finishing, should show summary page
    assert_text "Workout Complete!"
    assert_link "Back to Calendar"
  end

  # --- Workout summary ---

  test "shows summary page after finishing a workout with stats" do
    click_link "Start workout"
    click_button "Start Workout"

    # Add a set with reps
    select "Bench Press", from: "workout_set[exercise_id]"
    click_button "Start!"

    select "10\u00D7", from: "workout_rep[reps]"
    select "50.0kg", from: "workout_rep[weight]"
    click_button "+"

    click_button "Complete this set"

    accept_confirm { click_button "Finish" }

    # Should be on summary page with stats
    assert_text "Workout Complete!"
    assert_text "Total Volume"
    assert_text "500" # 50kg x 10 reps = 500kg
    assert_text "Sets"
    assert_text "1"
  end

  test "displays muscles worked with icons" do
    click_link "Start workout"
    click_button "Start Workout"

    select "Bench Press", from: "workout_set[exercise_id]"
    click_button "Start!"

    select "10\u00D7", from: "workout_rep[reps]"
    select "50.0kg", from: "workout_rep[weight]"
    click_button "+"

    click_button "Complete this set"
    accept_confirm { click_button "Finish" }

    assert_text "Muscles Worked"
    assert_text "Chest"
  end

  test "navigates to workout details from summary" do
    click_link "Start workout"
    click_button "Start Workout"

    accept_confirm { click_button "Finish" }

    click_link "View Details"
    assert_current_path workout_path(Workout.last)
  end

  test "navigates back to calendar from summary" do
    click_link "Start workout"
    click_button "Start Workout"

    accept_confirm { click_button "Finish" }

    click_link "Back to Calendar"
    assert_current_path workouts_path
  end

  test "shows first time message when no previous similar workout" do
    click_link "Start workout"
    click_button "Start Workout"

    accept_confirm { click_button "Finish" }

    assert_text "First time doing this workout!"
  end

  # --- Workout with sets ---

  test "allows adding a set to a workout" do
    click_link "Start workout"
    # Use default routine (Upper Lower / Upper Day) which has Bench Press
    click_button "Start Workout"

    select "Bench Press", from: "workout_set[exercise_id]"
    click_button "Start!"

    assert_text "Bench Press"
  end

  # --- Pausing and resuming ---

  test "allows pausing and resuming a workout" do
    click_link "Start workout"
    click_button "Start Workout"

    click_button "Pause"
    assert_button "Resume"

    click_button "Resume"
    assert_button "Pause"
  end

  # --- Deleting a workout from modal ---

  test "allows deleting a completed workout from the calendar modal" do
    assert_text "Workouts"

    # Create a completed workout for today so it shows in the calendar
    Workout.create!(
      user: @user,
      workout_type: :strength,
      started_at: Time.current.beginning_of_day + 10.hours,
      ended_at: Time.current.beginning_of_day + 11.hours,
      workout_routine_day: workout_routine_days(:push_day)
    )

    # Refresh the page to see the new workout
    visit workouts_path

    initial_count = @user.workouts.count

    # Click on the workout pill in the calendar to open modal
    first("a.bg-blue-600", text: /Push Day/i).click

    # Modal should be open with workout details
    assert_text "Push Day"

    within('[data-controller="modal"]') do
      assert_button "Delete"
      accept_confirm { click_button "Delete" }
    end

    # Wait for flash message to ensure deletion completed
    assert_text "Workout was successfully destroyed."
    assert_equal initial_count - 1, @user.workouts.reload.count
  end

  # --- Run workout form ---

  test "shows run fields when run type is selected and keeps them after validation error" do
    click_link "Start workout"

    # Select run workout type
    find("label", text: "Run").click

    # Run fields should be visible
    assert_field "workout[distance]"
    assert_field "workout[time_in_seconds]"

    # Submit with invalid data (negative distance)
    fill_in "workout[distance]", with: "-100"
    fill_in "workout[time_in_seconds]", with: "30:00"
    click_button "Start Workout"

    # Should show error and still have run fields visible
    assert_text "error"
    assert_field "workout[distance]"
    assert_field "workout[time_in_seconds]"
  end

  test "has day select available when switching back to strength after run validation error" do
    click_link "Start workout"

    # Select run workout type
    find("label", text: "Run").click

    # Submit with invalid data
    fill_in "workout[distance]", with: "-100"
    fill_in "workout[time_in_seconds]", with: "30:00"
    click_button "Start Workout"

    # Switch back to strength
    find("label", text: "Strength").click

    # Should have the day select available
    assert_selector "select[name='workout[workout_routine_day_id]']"
  end

  # --- Workout reps ---

  private def start_workout_with_bench_press
    click_link "Start workout"
    click_button "Start Workout"
    select "Bench Press", from: "workout_set[exercise_id]"
    click_button "Start!"
  end

  test "allows adding a rep with weight" do
    start_workout_with_bench_press

    select "10\u00D7", from: "workout_rep[reps]"
    select "20.0kg", from: "workout_rep[weight]"
    click_button "+"

    assert_text "10"
    assert_text "20"
  end

  test "allows adding multiple reps" do
    start_workout_with_bench_press

    select "10\u00D7", from: "workout_rep[reps]"
    select "20.0kg", from: "workout_rep[weight]"
    click_button "+"

    select "8\u00D7", from: "workout_rep[reps]"
    select "25.0kg", from: "workout_rep[weight]"
    click_button "+"

    assert_text "10"
    assert_text "20"
    assert_text "8"
    assert_text "25"
  end

  test "allows completing a set after adding reps" do
    start_workout_with_bench_press

    select "12\u00D7", from: "workout_rep[reps]"
    select "15.0kg", from: "workout_rep[weight]"
    click_button "+"

    click_button "Complete this set"

    # After completing, the set should still show the exercise name
    assert_text "Bench Press"
    # The "Complete this set" button should be gone for this set
    assert_no_button "Complete this set"
  end

  test "allows adding another set with a different exercise after completing one" do
    start_workout_with_bench_press

    select "10\u00D7", from: "workout_rep[reps]"
    select "20.0kg", from: "workout_rep[weight]"
    click_button "+"
    click_button "Complete this set"

    # Should be able to start another set with a different exercise
    select "Squat", from: "workout_set[exercise_id]"
    click_button "Start!"

    # New set form should appear for Squat
    assert_text "Squat"
    assert_selector "select[name='workout_rep[reps]']"
  end

  # --- Workout notes ---

  test "shows notes section on summary page" do
    click_link "Start workout"
    click_button "Start Workout"
    accept_confirm { click_button "Finish" }

    # Should be on summary page with notes section
    assert_text "Workout Complete!"
    assert_text "Notes"
    assert_link "Add note"
  end

  test "displays existing notes on summary page" do
    # Create a workout with notes
    workout =
      Workout.create!(
        user: @user,
        workout_type: :strength,
        started_at: 1.hour.ago,
        ended_at: Time.current,
        notes: "Great workout today!",
        workout_routine_day: workout_routine_days(:push_day)
      )

    visit summary_workout_path(workout)

    assert_text "Notes"
    assert_text "Great workout today!"
  end
end
