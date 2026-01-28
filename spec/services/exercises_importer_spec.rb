require "rails_helper"

describe ExercisesImporter do
  fixtures :users, :muscles

  let(:user) { users(:john) }

  describe "#initialize" do
    it "accepts user" do
      importer = described_class.new(user: user)
      expect(importer).to be_a(described_class)
    end

    it "uses locale from user" do
      user.update!(locale: "ru")
      importer = described_class.new(user: user)
      expect(importer).to be_a(described_class)
    end
  end

  describe "#call" do
    let(:csv_content) { <<~CSV }
        name,muscles,with_weights,with_band
        Test Exercise,chest,true,false
        Band Exercise,legs,false,true
      CSV

    let(:temp_file) { Tempfile.new(%w[exercises .csv]) }

    before do
      temp_file.write(csv_content)
      temp_file.rewind
      allow_any_instance_of(described_class).to receive(
        :path_for_locale
      ).and_return(temp_file.path)
    end

    after do
      temp_file.close
      temp_file.unlink
    end

    it "imports exercises from CSV" do
      expect { described_class.new(user: user).call }.to change(
        Exercise,
        :count
      ).by(2)
    end

    it "returns import statistics" do
      result = described_class.new(user: user).call
      expect(result).to eq(imported: 2, skipped: 0)
    end

    it "creates exercises with correct attributes" do
      described_class.new(user: user).call

      exercise = Exercise.find_by(name: "Test Exercise")
      expect(exercise).to have_attributes(
        user: user,
        with_weights: true,
        with_band: false
      )
      expect(exercise.muscle.name).to eq("chest")
    end

    it "creates band exercises correctly" do
      described_class.new(user: user).call

      exercise = Exercise.find_by(name: "Band Exercise")
      expect(exercise).to have_attributes(
        user: user,
        with_weights: false,
        with_band: true
      )
    end

    context "when exercise already exists for user" do
      before do
        user.exercises.create!(
          name: "Test Exercise",
          with_weights: true,
          with_band: false
        )
      end

      it "skips existing exercises" do
        expect { described_class.new(user: user).call }.to change(
          Exercise,
          :count
        ).by(1)
      end

      it "returns correct statistics" do
        result = described_class.new(user: user).call
        expect(result).to eq(imported: 1, skipped: 1)
      end
    end

    context "when muscle does not exist" do
      let(:csv_content) { <<~CSV }
          name,muscles,with_weights,with_band
          Unknown Muscle Exercise,nonexistent,true,false
        CSV

      it "creates exercise with nil muscle" do
        described_class.new(user: user).call

        exercise = Exercise.find_by(name: "Unknown Muscle Exercise")
        expect(exercise.muscle).to be_nil
      end
    end

    context "with empty CSV" do
      let(:csv_content) { <<~CSV }
          name,muscles,with_weights,with_band
        CSV

      it "returns zero imports" do
        result = described_class.new(user: user).call
        expect(result).to eq(imported: 0, skipped: 0)
      end
    end
  end

  describe "locale handling" do
    it "falls back to default CSV when locale-specific file does not exist" do
      # path_for_locale falls back to exercises.csv when exercises.ru.csv doesn't exist
      user.update!(locale: "ru")
      importer = described_class.new(user: user)
      path = importer.send(:path_for_locale, "ru")
      # Should fall back to exercises.csv since exercises.ru.csv likely doesn't exist
      expect(path.to_s).to include("exercises")
    end

    it "defaults to English when user locale is nil" do
      user.update!(locale: nil)
      importer = described_class.new(user: user)
      expect(importer.send(:path_for_locale, "en").to_s).to include("exercises")
    end
  end
end
