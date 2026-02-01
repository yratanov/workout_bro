require "rails_helper"

describe "Supersets" do
  fixtures :all

  let(:user) { users(:john) }

  before do
    login_as(user)
    expect(page).to have_content("Workouts")
  end

  describe "listing supersets" do
    it "shows all user supersets" do
      visit supersets_path

      expect(page).to have_content("Supersets")
      expect(page).to have_content(supersets(:push_pull).name)
      expect(page).to have_content(supersets(:arm_circuit).name)
    end
  end

  describe "creating a superset" do
    it "creates a new superset" do
      visit supersets_path
      click_link "New superset"

      fill_in "Name", with: "My New Superset"
      click_button "Save"

      expect(page).to have_content("Superset was successfully created")
      expect(page).to have_content("My New Superset")
    end
  end

  describe "viewing a superset" do
    it "shows superset details and exercises" do
      superset = supersets(:push_pull)
      visit superset_path(superset)

      expect(page).to have_content(superset.name)
      superset.exercises.each do |exercise|
        expect(page).to have_content(exercise.name)
      end
    end
  end

  describe "adding exercises to superset" do
    it "adds an exercise to the superset" do
      superset = supersets(:push_pull)
      visit superset_path(superset)

      click_link "Add exercise"

      select "Squat", from: "superset_exercise[exercise_id]"
      click_button "Add"

      expect(page).to have_content("Squat")
      expect(superset.reload.exercises).to include(exercises(:squat))
    end
  end

  describe "deleting a superset" do
    it "deletes the superset" do
      superset = user.supersets.create!(name: "Superset to Delete")
      visit superset_path(superset)

      accept_confirm { click_button "Delete" }

      expect(page).to have_current_path(supersets_path)
      expect(Superset.find_by(id: superset.id)).to be_nil
    end
  end
end
