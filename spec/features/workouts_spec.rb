require 'rails_helper'

RSpec.describe "Workouts", type: :feature do
  fixtures :users, :exercises, :workout_routines, :workout_routine_days, :workout_routine_day_exercises

  let(:user) { users(:one) }

  before do
    login_as(user)
  end

  describe "viewing workouts" do
    it "shows the workouts index page" do
      expect(page).to have_content("Workouts")
      expect(page).to have_link("Start workout")
    end
  end

  describe "starting a strength workout" do
    it "allows starting a new workout with default routine" do
      click_link "Start workout"

      expect(page).to have_content("New Workout")
      # Default routine is Upper Lower with Upper Day pre-selected
      click_button "Start Workout"

      expect(page).to have_content("Upper Lower")
      expect(page).to have_content("Upper Day")
      expect(page).to have_button("Finish workout")
    end

    it "allows selecting a different routine", :js, pending: "Turbo stream fetch not triggering in test environment" do
      click_link "Start workout"

      # Find the routine select and change it
      routine_select = find('select[name="workout[workout_routine_day]"]')
      routine_select.select "Push Pull Legs"

      # Wait for the Turbo stream to update the day options
      using_wait_time(10) do
        expect(page).to have_select("workout[workout_routine_day_id]", with_options: ["Push Day"])
      end
      select "Push Day", from: "workout[workout_routine_day_id]"
      click_button "Start Workout"

      expect(page).to have_content("Push Pull Legs")
      expect(page).to have_content("Push Day")
      expect(page).to have_button("Finish workout")
    end
  end

  describe "completing a workout" do
    it "allows finishing an active workout" do
      click_link "Start workout"
      click_button "Start Workout"

      accept_confirm do
        click_button "Finish workout"
      end

      # After finishing, should redirect to workouts index
      expect(page).to have_content("Workouts")
      expect(page).to have_link("Start workout")
    end
  end

  describe "workout with sets" do
    it "allows adding a set to a workout" do
      click_link "Start workout"
      # Use default routine (Upper Lower / Upper Day) which has Bench Press
      click_button "Start Workout"

      select "Bench Press", from: "workout_set[exercise_id]"
      click_button "Start!"

      expect(page).to have_content("Bench Press")
    end
  end

  describe "pausing and resuming a workout" do
    it "allows pausing and resuming a workout" do
      click_link "Start workout"
      click_button "Start Workout"

      click_button "Pause"
      expect(page).to have_button("Resume")

      click_button "Resume"
      expect(page).to have_button("Pause")
    end
  end

  describe "deleting a workout from modal" do
    it "allows deleting a completed workout from the calendar modal" do
      # Verify we're on the workouts page (logged in from before block)
      expect(page).to have_content("Workouts")

      # Create a completed workout for today so it shows in the calendar
      Workout.create!(
        user: user,
        workout_type: :strength,
        started_at: Time.current.beginning_of_day + 10.hours,
        ended_at: Time.current.beginning_of_day + 11.hours,
        workout_routine_day: workout_routine_days(:push_day)
      )

      # Refresh the page to see the new workout
      visit workouts_path

      initial_count = user.workouts.count

      # Click on the workout pill in the calendar to open modal
      first('button.bg-blue-600', text: /Push Day/i).click

      # Modal should be open with workout details
      expect(page).to have_content("Push Day")
      expect(page).to have_button("Delete")

      # Click delete and confirm
      accept_confirm do
        click_button "Delete"
      end

      # Should redirect to workouts index and workout count should decrease
      expect(page).to have_current_path(workouts_path)
      expect(user.workouts.reload.count).to eq(initial_count - 1)
    end
  end

  describe "workout reps" do
    before do
      click_link "Start workout"
      click_button "Start Workout"
      select "Bench Press", from: "workout_set[exercise_id]"
      click_button "Start!"
    end

    it "allows adding a rep with weight" do
      select "10 x", from: "workout_rep[reps]"
      select "20.0KG", from: "workout_rep[weight]"
      click_button "Add"

      expect(page).to have_content("10")
      expect(page).to have_content("20.0KG")
    end

    it "allows adding multiple reps" do
      select "10 x", from: "workout_rep[reps]"
      select "20.0KG", from: "workout_rep[weight]"
      click_button "Add"

      select "8 x", from: "workout_rep[reps]"
      select "25.0KG", from: "workout_rep[weight]"
      click_button "Add"

      expect(page).to have_content("10")
      expect(page).to have_content("20.0KG")
      expect(page).to have_content("8")
      expect(page).to have_content("25.0KG")
    end

    it "allows completing a set after adding reps" do
      select "12 x", from: "workout_rep[reps]"
      select "15.0KG", from: "workout_rep[weight]"
      click_button "Add"

      click_button "Complete this set"

      # After completing, the set should still show the exercise name
      expect(page).to have_content("Bench Press")
      # The "Complete this set" button should be gone for this set
      expect(page).not_to have_button("Complete this set")
    end

    it "allows adding another set with a different exercise after completing one" do
      select "10 x", from: "workout_rep[reps]"
      select "20.0KG", from: "workout_rep[weight]"
      click_button "Add"
      click_button "Complete this set"

      # Should be able to start another set with a different exercise
      # (Bench Press is no longer available since it was already used)
      select "Squat", from: "workout_set[exercise_id]"
      click_button "Start!"

      # New set form should appear for Squat
      expect(page).to have_content("Squat")
      expect(page).to have_select("workout_rep[reps]")
    end
  end
end
