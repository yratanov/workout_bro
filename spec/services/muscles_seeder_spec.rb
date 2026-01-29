describe MusclesSeeder do
  fixtures :muscles

  describe "#call" do
    context "when all muscles already exist from fixtures" do
      it "skips all existing muscles" do
        result = described_class.new.call

        expect(result[:skipped]).to eq(8)
        expect(result[:created]).to eq(0)
      end
    end

    context "when a new muscle name is added" do
      before do
        stub_const(
          "MusclesSeeder::MUSCLES",
          %w[chest back shoulders biceps triceps legs glutes core newmuscle]
        )
      end

      it "creates only the new muscle" do
        result = described_class.new.call

        expect(result[:created]).to eq(1)
        expect(Muscle.find_by(name: "newmuscle")).to be_present
      end
    end

    it "returns a hash with created and skipped counts" do
      result = described_class.new.call

      expect(result).to be_a(Hash)
      expect(result).to have_key(:created)
      expect(result).to have_key(:skipped)
    end
  end
end
