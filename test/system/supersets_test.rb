require "application_system_test_case"

class SupersetsTest < ApplicationSystemTestCase
  setup do
    login_as(users(:john))
    assert_text "Workouts"
  end

  test "shows all user supersets" do
    visit supersets_path

    assert_text "Supersets"
    assert_text supersets(:push_pull).name
    assert_text supersets(:arm_circuit).name
  end

  test "creates a new superset" do
    visit supersets_path
    click_link "New superset"

    fill_in "Name", with: "My New Superset"
    click_button "Save"

    assert_text "Superset was successfully created"
    assert_text "My New Superset"
  end

  test "shows superset details and exercises" do
    superset = supersets(:push_pull)
    visit superset_path(superset)

    assert_text superset.name
    superset.exercises.each { |exercise| assert_text exercise.name }
  end

  test "adds an exercise to the superset" do
    superset = supersets(:push_pull)
    visit superset_path(superset)

    click_link "Add exercise"

    select "Squat", from: "superset_exercise[exercise_id]"
    click_button "Add"

    assert_text "Squat"
    assert_includes superset.reload.exercises, exercises(:squat)
  end

  test "deletes the superset" do
    user = users(:john)
    superset = user.supersets.create!(name: "Superset to Delete")
    visit superset_path(superset)

    accept_confirm { click_button "Delete" }

    assert_current_path supersets_path
    assert_nil Superset.find_by(id: superset.id)
  end
end
