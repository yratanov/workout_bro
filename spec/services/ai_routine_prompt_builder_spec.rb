describe AiRoutinePromptBuilder do
  fixtures :all

  let(:user) { users(:john) }
  let(:params) do
    {
      frequency: "4",
      split_type: "Upper/Lower",
      experience_level: "Intermediate",
      focus_areas: %w[chest back],
      additional_context: "No shoulder injuries"
    }
  end

  describe "#call" do
    it "includes task instructions mentioning new exercises and supersets" do
      result = described_class.new(user, params).call
      expect(result).to include("workout routine")
      expect(result).to include("new exercises")
      expect(result).to include("supersets")
    end

    it "includes user preferences" do
      result = described_class.new(user, params).call
      expect(result).to include("4 days per week")
      expect(result).to include("Upper/Lower")
      expect(result).to include("Intermediate")
      expect(result).to include("chest, back")
      expect(result).to include("No shoulder injuries")
    end

    it "includes exercise list" do
      result = described_class.new(user, params).call
      expect(result).to include("Bench Press")
      expect(result).to include("Squat")
      expect(result).to include("Deadlift")
    end

    it "includes superset list" do
      result = described_class.new(user, params).call
      expect(result).to include("Available Supersets")
      expect(result).to include("Push Pull")
      expect(result).to include("Arm Circuit")
    end

    it "includes valid muscle group names" do
      result = described_class.new(user, params).call
      expect(result).to include("Valid Muscle Groups")
      expect(result).to include("chest")
      expect(result).to include("back")
      expect(result).to include("legs")
    end

    it "includes new JSON format with object exercises and superset examples" do
      result = described_class.new(user, params).call
      expect(result).to include('"name": "Exercise Name"')
      expect(result).to include('"muscle": "chest"')
      expect(result).to include('"superset": "Superset Name"')
    end

    it "includes comment field in the JSON format example" do
      result = described_class.new(user, params).call
      expect(result).to include('"comment"')
      expect(result).to include("concise")
    end

    it "includes output format instructions" do
      result = described_class.new(user, params).call
      expect(result).to include("JSON")
      expect(result).to include("4")
    end

    it "omits focus areas when empty" do
      params[:focus_areas] = []
      result = described_class.new(user, params).call
      expect(result).not_to include("Focus areas")
    end

    it "omits additional context when blank" do
      params[:additional_context] = ""
      result = described_class.new(user, params).call
      expect(result).not_to include("Additional context")
    end

    it "omits superset section when user has no supersets" do
      user_without_supersets = users(:jane)
      result = described_class.new(user_without_supersets, params).call
      expect(result).not_to include("Available Supersets")
    end
  end
end
