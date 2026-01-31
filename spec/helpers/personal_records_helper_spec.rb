describe PersonalRecordsHelper do
  describe "#pr_type_badge_class" do
    it "returns yellow classes for max_weight" do
      expect(helper.pr_type_badge_class("max_weight")).to eq(
        "bg-yellow-600/20 text-yellow-400"
      )
    end

    it "returns green classes for max_volume" do
      expect(helper.pr_type_badge_class("max_volume")).to eq(
        "bg-green-600/20 text-green-400"
      )
    end

    it "returns blue classes for max_reps" do
      expect(helper.pr_type_badge_class("max_reps")).to eq(
        "bg-blue-600/20 text-blue-400"
      )
    end

    it "returns slate classes for unknown types" do
      expect(helper.pr_type_badge_class("unknown")).to eq(
        "bg-slate-600/20 text-slate-400"
      )
    end

    it "handles symbol input" do
      expect(helper.pr_type_badge_class(:max_weight)).to eq(
        "bg-yellow-600/20 text-yellow-400"
      )
    end
  end
end
