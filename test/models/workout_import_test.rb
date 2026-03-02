require "test_helper"

# == Schema Information
#
# Table name: workout_imports
# Database name: primary
#
#  id                :integer          not null, primary key
#  error_details     :json
#  imported_count    :integer          default(0), not null
#  original_filename :string
#  skipped_count     :integer          default(0), not null
#  status            :integer          default("pending"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  user_id           :integer          not null
#
# Indexes
#
#  index_workout_imports_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

class WorkoutImportTest < ActiveSupport::TestCase
  test "associations - has many workouts with dependent nullify" do
    import = workout_imports(:pending_import)
    assert import.respond_to?(:workouts)
  end

  test "associations - belongs to user" do
    import = workout_imports(:pending_import)
    assert import.respond_to?(:user)
  end

  test "validates presence of status" do
    import = WorkoutImport.new(user: users(:john), status: nil)
    import.file.attach(
      io: StringIO.new("test,data"),
      filename: "test.csv",
      content_type: "text/csv"
    )
    assert_not import.valid?
  end

  test "requires a file to be attached" do
    import = WorkoutImport.new(user: users(:john))
    assert_not import.valid?
    assert_includes import.errors[:file], "can't be blank"
  end

  test "accepts CSV files" do
    import = WorkoutImport.new(user: users(:john))
    import.file.attach(
      io: StringIO.new("test,data"),
      filename: "test.csv",
      content_type: "text/csv"
    )
    assert import.valid?
  end

  test "rejects non-CSV files by content type" do
    import = WorkoutImport.new(user: users(:john))
    import.file.attach(
      io: StringIO.new("not a csv"),
      filename: "test.txt",
      content_type: "text/plain"
    )
    assert_not import.valid?
    assert_includes import.errors[:file], "must be a CSV file"
  end

  test "accepts files with .csv extension regardless of content type" do
    import = WorkoutImport.new(user: users(:john))
    import.file.attach(
      io: StringIO.new("data"),
      filename: "data.csv",
      content_type: "application/octet-stream"
    )
    assert import.valid?
  end

  test "defines status enum with correct values" do
    assert_equal(
      { "pending" => 0, "in_progress" => 1, "completed" => 2, "failed" => 3 },
      WorkoutImport.statuses
    )
  end

  test "defaults to pending status" do
    import = workout_imports(:pending_import)
    assert_equal "pending", import.status
  end

  test "can transition to in_progress" do
    import = workout_imports(:pending_import)
    import.in_progress!
    assert import.in_progress?
  end

  test "can transition to completed" do
    import = workout_imports(:pending_import)
    import.completed!
    assert import.completed?
  end

  test "can transition to failed" do
    import = workout_imports(:pending_import)
    import.failed!
    assert import.failed?
  end

  test "defaults imported_count to 0" do
    import = workout_imports(:pending_import)
    assert_equal 0, import.imported_count
  end

  test "defaults skipped_count to 0" do
    import = workout_imports(:pending_import)
    assert_equal 0, import.skipped_count
  end

  test "can attach a file" do
    assert workout_imports(:pending_import).file.attached?
  end

  test "nullifies workout_import_id when destroyed" do
    user = users(:john)
    import = workout_imports(:pending_import)
    workout =
      user.workouts.create!(
        workout_type: :strength,
        started_at: Time.current,
        ended_at: Time.current + 1.hour,
        workout_import: import
      )

    import.destroy!
    workout.reload

    assert_nil workout.workout_import_id
  end
end
