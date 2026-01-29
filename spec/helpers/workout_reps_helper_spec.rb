describe WorkoutRepsHelper do
  fixtures :users

  describe "#weight_options" do
    it "generates options based on user weight settings" do
      user = users(:john)
      user.weight_min = 5
      user.weight_max = 15
      user.weight_step = 5
      user.weight_unit = "kg"

      options = helper.weight_options(user)

      expect(options).to eq(
        [["5.0kg", 5.0], ["10.0kg", 10.0], ["15.0kg", 15.0]]
      )
    end

    it "uses the correct weight unit" do
      user = users(:john)
      user.weight_min = 10
      user.weight_max = 20
      user.weight_step = 5
      user.weight_unit = "lbs"

      options = helper.weight_options(user)

      expect(options).to eq(
        [["10.0lbs", 10.0], ["15.0lbs", 15.0], ["20.0lbs", 20.0]]
      )
    end

    it "handles decimal steps" do
      user = users(:john)
      user.weight_min = 2.5
      user.weight_max = 7.5
      user.weight_step = 2.5
      user.weight_unit = "kg"

      options = helper.weight_options(user)

      expect(options).to eq([["2.5kg", 2.5], ["5.0kg", 5.0], ["7.5kg", 7.5]])
    end
  end
end
