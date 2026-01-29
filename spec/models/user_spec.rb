describe User do
  fixtures :users

  let(:user) { users(:john) }

  describe "weight settings validations" do
    describe "weight_unit" do
      it "is valid with 'kg'" do
        user.weight_unit = "kg"
        expect(user).to be_valid
      end

      it "is valid with 'lbs'" do
        user.weight_unit = "lbs"
        expect(user).to be_valid
      end

      it "is invalid with other values" do
        user.weight_unit = "stones"
        expect(user).not_to be_valid
        expect(user.errors[:weight_unit]).to include(
          "is not included in the list"
        )
      end
    end

    describe "weight_min" do
      it "is valid with positive values" do
        user.weight_min = 5
        expect(user).to be_valid
      end

      it "is invalid with zero" do
        user.weight_min = 0
        expect(user).not_to be_valid
        expect(user.errors[:weight_min]).to include("must be greater than 0")
      end

      it "is invalid with negative values" do
        user.weight_min = -1
        expect(user).not_to be_valid
        expect(user.errors[:weight_min]).to include("must be greater than 0")
      end
    end

    describe "weight_max" do
      it "is valid when greater than weight_min" do
        user.weight_min = 5
        user.weight_max = 100
        expect(user).to be_valid
      end

      it "is invalid when equal to weight_min" do
        user.weight_min = 50
        user.weight_max = 50
        expect(user).not_to be_valid
        expect(user.errors[:weight_max]).to include("must be greater than 50.0")
      end

      it "is invalid when less than weight_min" do
        user.weight_min = 50
        user.weight_max = 25
        expect(user).not_to be_valid
        expect(user.errors[:weight_max]).to include("must be greater than 50.0")
      end
    end

    describe "weight_step" do
      it "is valid with positive values" do
        user.weight_step = 2.5
        expect(user).to be_valid
      end

      it "is invalid with zero" do
        user.weight_step = 0
        expect(user).not_to be_valid
        expect(user.errors[:weight_step]).to include("must be greater than 0")
      end

      it "is invalid with negative values" do
        user.weight_step = -1
        expect(user).not_to be_valid
        expect(user.errors[:weight_step]).to include("must be greater than 0")
      end
    end
  end

  describe "default values" do
    it "has default weight_unit of 'kg'" do
      new_user =
        User.new(email_address: "test@example.com", password: "password")
      expect(new_user.weight_unit).to eq("kg")
    end

    it "has default weight_min of 2.5" do
      new_user =
        User.new(email_address: "test@example.com", password: "password")
      expect(new_user.weight_min).to eq(2.5)
    end

    it "has default weight_max of 100" do
      new_user =
        User.new(email_address: "test@example.com", password: "password")
      expect(new_user.weight_max).to eq(100)
    end

    it "has default weight_step of 2.5" do
      new_user =
        User.new(email_address: "test@example.com", password: "password")
      expect(new_user.weight_step).to eq(2.5)
    end
  end
end
