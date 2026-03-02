require "application_system_test_case"

class ExercisesTest < ApplicationSystemTestCase
  setup do
    login_as(users(:john))
    assert_text "Workouts"
  end

  test "allows deleting an exercise from the edit page" do
    user = users(:john)
    exercise =
      Exercise.create!(
        name: "Test Exercise for Deletion",
        muscle: muscles(:chest),
        user: user
      )

    visit exercise_path(exercise)

    assert_text "Test Exercise for Deletion"
    click_link "Edit"

    assert_text "Edit exercise"

    initial_count = Exercise.count

    accept_confirm { click_button "Delete" }

    assert_current_path exercises_path
    assert_equal initial_count - 1, Exercise.count
    assert_nil Exercise.find_by(id: exercise.id)
  end

  test "allows deleting an exercise from the show page" do
    user = users(:john)
    exercise =
      Exercise.create!(
        name: "Test Exercise for Show Deletion",
        muscle: muscles(:chest),
        user: user
      )

    visit exercise_path(exercise)

    assert_text "Test Exercise for Show Deletion"

    initial_count = Exercise.count

    accept_confirm { click_button "Delete" }

    assert_current_path exercises_path
    assert_equal initial_count - 1, Exercise.count
    assert_nil Exercise.find_by(id: exercise.id)
  end
end
