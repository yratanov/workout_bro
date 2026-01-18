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

      expect(page).to have_content("New workout")
      # Default routine is Upper Lower with Upper Day pre-selected
      click_button "Start"

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
      click_button "Start"

      expect(page).to have_content("Push Pull Legs")
      expect(page).to have_content("Push Day")
      expect(page).to have_button("Finish workout")
    end
  end

  describe "completing a workout" do
    it "allows finishing an active workout" do
      click_link "Start workout"
      click_button "Start"

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
      click_button "Start"

      select "Bench Press", from: "workout_set[exercise_id]"
      click_button "Start!"

      expect(page).to have_content("Bench Press")
    end
  end

  describe "pausing and resuming a workout" do
    it "allows pausing and resuming a workout" do
      click_link "Start workout"
      click_button "Start"

      click_button "Pause"
      expect(page).to have_button("Resume")

      click_button "Resume"
      expect(page).to have_button("Pause")
    end
  end

  describe "workout reps" do
    before do
      click_link "Start workout"
      click_button "Start"
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
