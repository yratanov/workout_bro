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
end
