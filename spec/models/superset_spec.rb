describe Superset do
  fixtures :users, :exercises, :supersets, :superset_exercises

  describe "validations" do
    it "requires a name" do
      superset = Superset.new(user: users(:john))
      expect(superset).not_to be_valid
      expect(superset.errors[:name]).to include("can't be blank")
    end

    it "requires a user" do
      superset = Superset.new(name: "Test Superset")
      expect(superset).not_to be_valid
      expect(superset.errors[:user]).to include("must exist")
    end

    it "is valid with name and user" do
      superset = Superset.new(name: "Test Superset", user: users(:john))
      expect(superset).to be_valid
    end
  end

  describe "associations" do
    let(:superset) { supersets(:push_pull) }

    it "has many superset_exercises" do
      expect(superset.superset_exercises.count).to eq(2)
    end

    it "has many exercises through superset_exercises" do
      expect(superset.exercises).to include(
        exercises(:bench_press),
        exercises(:pull_up)
      )
    end

    it "orders superset_exercises by position" do
      positions = superset.superset_exercises.pluck(:position)
      expect(positions).to eq(positions.sort)
    end
  end

  describe "#display_name" do
    it "returns the superset name" do
      superset = supersets(:push_pull)
      expect(superset.display_name).to eq("Push Pull")
    end
  end

  describe "dependent destroy" do
    it "destroys superset_exercises when superset is destroyed" do
      superset = supersets(:push_pull)
      superset_exercise_ids = superset.superset_exercises.pluck(:id)

      superset.destroy

      superset_exercise_ids.each do |id|
        expect(SupersetExercise.find_by(id: id)).to be_nil
      end
    end
  end
end
