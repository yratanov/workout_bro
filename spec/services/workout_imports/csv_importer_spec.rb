describe WorkoutImports::CsvImporter do
  fixtures :all

  let(:user) { users(:john) }
  let(:workout_import) { workout_imports(:pending_import) }

  describe "#call" do
    context "with custom format CSV" do
      let(:csv_content) { <<~CSV }
          2024-01-15,,,,
          Bench Press,60x10,70x8,,

          2024-01-17,,,,
          Squat,100x5,110x5,,
        CSV

      before do
        workout_import.file.attach(
          io: StringIO.new(csv_content),
          filename: "workouts.csv",
          content_type: "text/csv"
        )
      end

      it "imports workouts from custom format CSV" do
        result = described_class.new(workout_import).call

        expect(result[:imported]).to eq(2)
        expect(workout_import.reload).to be_completed
      end

      it "creates workout records with correct associations" do
        described_class.new(workout_import).call

        expect(user.workouts.where(workout_import: workout_import).count).to eq(
          2
        )
      end

      it "updates workout_import counters" do
        described_class.new(workout_import).call

        workout_import.reload
        expect(workout_import.imported_count).to eq(2)
        expect(workout_import.skipped_count).to eq(0)
      end
    end

    context "when import fails" do
      before do
        allow_any_instance_of(WorkoutImports::FormatDetector).to receive(
          :parser_class
        ).and_raise(StandardError, "Test error")
        workout_import.file.attach(
          io: StringIO.new("invalid"),
          filename: "bad.csv",
          content_type: "text/csv"
        )
      end

      it "sets status to failed" do
        described_class.new(workout_import).call

        expect(workout_import.reload).to be_failed
      end

      it "records error details" do
        described_class.new(workout_import).call

        expect(workout_import.reload.error_details["message"]).to eq(
          "Test error"
        )
      end
    end
  end
end
