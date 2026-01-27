# == Schema Information
#
# Table name: workout_imports
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
require "rails_helper"

RSpec.describe WorkoutImport, type: :model do
  fixtures :users

  let(:user) { users(:one) }
  let(:csv_file) do
    {
      io: StringIO.new("test,data"),
      filename: "test.csv",
      content_type: "text/csv"
    }
  end

  def create_workout_import(attrs = {})
    import = described_class.new(user: user, **attrs)
    import.file.attach(csv_file) unless attrs[:skip_file]
    import.save!
    import
  end

  describe "associations" do
    it { should belong_to(:user) }
    it { should have_many(:workouts).dependent(:nullify) }
  end

  describe "validations" do
    it { should validate_presence_of(:status) }

    it "requires a file to be attached" do
      import = described_class.new(user: user)
      expect(import).not_to be_valid
      expect(import.errors[:file]).to include("can't be blank")
    end

    it "accepts CSV files" do
      import = described_class.new(user: user)
      import.file.attach(csv_file)
      expect(import).to be_valid
    end

    it "rejects non-CSV files by content type" do
      import = described_class.new(user: user)
      import.file.attach(
        io: StringIO.new("not a csv"),
        filename: "test.txt",
        content_type: "text/plain"
      )
      expect(import).not_to be_valid
      expect(import.errors[:file]).to include("must be a CSV file")
    end

    it "accepts files with .csv extension regardless of content type" do
      import = described_class.new(user: user)
      import.file.attach(
        io: StringIO.new("data"),
        filename: "data.csv",
        content_type: "application/octet-stream"
      )
      expect(import).to be_valid
    end
  end

  describe "enums" do
    it "defines status enum with correct values" do
      expect(described_class.statuses).to eq({
        "pending" => 0,
        "in_progress" => 1,
        "completed" => 2,
        "failed" => 3
      })
    end
  end

  describe "status transitions" do
    let(:workout_import) { create_workout_import }

    it "defaults to pending status" do
      expect(workout_import.status).to eq("pending")
    end

    it "can transition to in_progress" do
      workout_import.in_progress!
      expect(workout_import).to be_in_progress
    end

    it "can transition to completed" do
      workout_import.completed!
      expect(workout_import).to be_completed
    end

    it "can transition to failed" do
      workout_import.failed!
      expect(workout_import).to be_failed
    end
  end

  describe "counter defaults" do
    let(:workout_import) { create_workout_import }

    it "defaults imported_count to 0" do
      expect(workout_import.imported_count).to eq(0)
    end

    it "defaults skipped_count to 0" do
      expect(workout_import.skipped_count).to eq(0)
    end
  end

  describe "file attachment" do
    it "can attach a file" do
      workout_import = create_workout_import
      expect(workout_import.file).to be_attached
    end
  end

  describe "workouts association" do
    let(:workout_import) { create_workout_import }

    it "nullifies workout_import_id when destroyed" do
      workout = user.workouts.create!(
        workout_type: :strength,
        started_at: Time.current,
        ended_at: Time.current + 1.hour,
        workout_import: workout_import
      )

      workout_import.destroy!
      workout.reload

      expect(workout.workout_import_id).to be_nil
    end
  end
end
