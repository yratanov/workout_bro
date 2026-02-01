require "rails_helper"

describe "Workouts" do
  fixtures :users,
           :exercises,
           :workout_routines,
           :workout_routine_days,
           :workout_routine_day_exercises

  let(:user) { users(:john) }

  before { login_as(user) }

  describe "viewing workouts" do
    it "shows the workouts index page" do
      expect(page).to have_content("Workouts")
      expect(page).to have_link("Start workout")
      workouts(:completed_workout, :active_workout).each do |workout|
        workout.destroy
      end
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
      expect(page).to have_button("Finish")
    end
  end

  describe "completing a workout" do
    it "allows finishing an active workout and shows summary" do
      click_link "Start workout"
      click_button "Start Workout"

      accept_confirm { click_button "Finish" }

      # After finishing, should show summary page
      expect(page).to have_content("Workout Complete!")
      expect(page).to have_link("Back to Calendar")
    end
  end

  describe "workout summary" do
    it "shows summary page after finishing a workout with stats" do
      click_link "Start workout"
      click_button "Start Workout"

      # Add a set with reps
      select "Bench Press", from: "workout_set[exercise_id]"
      click_button "Start!"

      select "10×", from: "workout_rep[reps]"
      select "50.0kg", from: "workout_rep[weight]"
      click_button "+"

      click_button "Complete this set"

      accept_confirm { click_button "Finish" }

      # Should be on summary page with stats
      expect(page).to have_content("Workout Complete!")
      expect(page).to have_content("Total Volume")
      expect(page).to have_content("500") # 50kg x 10 reps = 500kg
      expect(page).to have_content("Sets")
      expect(page).to have_content("1")
    end

    it "displays muscles worked with icons" do
      click_link "Start workout"
      click_button "Start Workout"

      select "Bench Press", from: "workout_set[exercise_id]"
      click_button "Start!"

      select "10×", from: "workout_rep[reps]"
      select "50.0kg", from: "workout_rep[weight]"
      click_button "+"

      click_button "Complete this set"
      accept_confirm { click_button "Finish" }

      expect(page).to have_content("Muscles Worked")
      expect(page).to have_content("Chest")
    end

    it "navigates to workout details from summary" do
      click_link "Start workout"
      click_button "Start Workout"

      accept_confirm { click_button "Finish" }

      click_link "View Details"
      expect(page).to have_current_path(workout_path(Workout.last))
    end

    it "navigates back to calendar from summary" do
      click_link "Start workout"
      click_button "Start Workout"

      accept_confirm { click_button "Finish" }

      click_link "Back to Calendar"
      expect(page).to have_current_path(workouts_path)
    end

    it "shows first time message when no previous similar workout" do
      click_link "Start workout"
      click_button "Start Workout"

      accept_confirm { click_button "Finish" }

      expect(page).to have_content("First time doing this workout!")
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
      first("a.bg-blue-600", text: /Push Day/i).click

      # Modal should be open with workout details
      expect(page).to have_content("Push Day")

      within('[data-controller="modal"]') do
        # Click delete and confirm
        expect(page).to have_button("Delete")
        accept_confirm { click_button "Delete" }
      end

      # Wait for flash message to ensure deletion completed
      expect(page).to have_content("Workout was successfully destroyed.")
      expect(user.workouts.reload.count).to eq(initial_count - 1)
    end
  end

  describe "run workout form" do
    it "shows run fields when run type is selected and keeps them after validation error" do
      click_link "Start workout"

      # Select run workout type
      find("label", text: "Run").click

      # Run fields should be visible
      expect(page).to have_field("workout[distance]")
      expect(page).to have_field("workout[time_in_seconds]")

      # Submit with invalid data (negative distance)
      fill_in "workout[distance]", with: "-100"
      fill_in "workout[time_in_seconds]", with: "30:00"
      click_button "Start Workout"

      # Should show error and still have run fields visible
      expect(page).to have_content("error")
      expect(page).to have_field("workout[distance]")
      expect(page).to have_field("workout[time_in_seconds]")
    end

    it "has day select available when switching back to strength after run validation error" do
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
      expect(page).to have_select("workout[workout_routine_day_id]")
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
      select "10×", from: "workout_rep[reps]"
      select "20.0kg", from: "workout_rep[weight]"
      click_button "+"

      expect(page).to have_content("10")
      expect(page).to have_content("20")
    end

    it "allows adding multiple reps" do
      select "10×", from: "workout_rep[reps]"
      select "20.0kg", from: "workout_rep[weight]"
      click_button "+"

      select "8×", from: "workout_rep[reps]"
      select "25.0kg", from: "workout_rep[weight]"
      click_button "+"

      expect(page).to have_content("10")
      expect(page).to have_content("20")
      expect(page).to have_content("8")
      expect(page).to have_content("25")
    end

    it "allows completing a set after adding reps" do
      select "12×", from: "workout_rep[reps]"
      select "15.0kg", from: "workout_rep[weight]"
      click_button "+"

      click_button "Complete this set"

      # After completing, the set should still show the exercise name
      expect(page).to have_content("Bench Press")
      # The "Complete this set" button should be gone for this set
      expect(page).not_to have_button("Complete this set")
    end

    it "allows adding another set with a different exercise after completing one" do
      select "10×", from: "workout_rep[reps]"
      select "20.0kg", from: "workout_rep[weight]"
      click_button "+"
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

  describe "workout notes" do
    it "shows notes section on summary page" do
      click_link "Start workout"
      click_button "Start Workout"
      accept_confirm { click_button "Finish" }

      # Should be on summary page with notes section
      expect(page).to have_content("Workout Complete!")
      expect(page).to have_content("Notes")
      expect(page).to have_link("Add note")
    end

    it "displays existing notes on summary page" do
      # Create a workout with notes
      workout =
        Workout.create!(
          user: user,
          workout_type: :strength,
          started_at: 1.hour.ago,
          ended_at: Time.current,
          notes: "Great workout today!",
          workout_routine_day: workout_routine_days(:push_day)
        )

      visit summary_workout_path(workout)

      expect(page).to have_content("Notes")
      expect(page).to have_content("Great workout today!")
    end
  end
end
