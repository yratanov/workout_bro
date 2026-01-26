require 'rails_helper'

RSpec.describe "Exercises", type: :feature do
  let(:user) { users(:one) }

  before do
    login_as(user)
    expect(page).to have_content("Workouts")
  end

  describe "deleting an exercise" do
    it "allows deleting an exercise from the edit page" do
      exercise = Exercise.create!(name: "Test Exercise for Deletion", muscle: muscles(:chest), user: user)

      visit exercise_path(exercise)

      expect(page).to have_content("Test Exercise for Deletion")
      click_link "Edit"

      expect(page).to have_content("Edit exercise")

      initial_count = Exercise.count

      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_current_path(exercises_path)
      expect(Exercise.count).to eq(initial_count - 1)
      expect(Exercise.find_by(id: exercise.id)).to be_nil
    end

    it "allows deleting an exercise from the show page" do
      exercise = Exercise.create!(name: "Test Exercise for Show Deletion", muscle: muscles(:chest), user: user)

      visit exercise_path(exercise)

      expect(page).to have_content("Test Exercise for Show Deletion")

      initial_count = Exercise.count

      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_current_path(exercises_path)
      expect(Exercise.count).to eq(initial_count - 1)
      expect(Exercise.find_by(id: exercise.id)).to be_nil
    end
  end
end
