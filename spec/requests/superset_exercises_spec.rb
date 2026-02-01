describe "SupersetExercises" do
  fixtures :users, :exercises, :supersets, :superset_exercises

  let(:user) { users(:john) }
  let(:superset) { supersets(:push_pull) }
  let(:exercise) { exercises(:squat) }

  before { sign_in(user) }

  describe "GET /supersets/:superset_id/superset_exercises/new" do
    it "returns success" do
      get new_superset_superset_exercise_path(superset)
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /supersets/:superset_id/superset_exercises" do
    context "with valid params" do
      it "creates a new superset exercise" do
        expect {
          post superset_superset_exercises_path(superset),
               params: {
                 superset_exercise: {
                   exercise_id: exercise.id
                 }
               },
               as: :turbo_stream
        }.to change(SupersetExercise, :count).by(1)
      end

      it "sets position automatically" do
        post superset_superset_exercises_path(superset),
             params: {
               superset_exercise: {
                 exercise_id: exercise.id
               }
             },
             as: :turbo_stream
        expect(SupersetExercise.last.position).to eq(3)
      end
    end

    context "with invalid params" do
      it "returns unprocessable entity for duplicate exercise" do
        existing_exercise = superset.exercises.first
        post superset_superset_exercises_path(superset),
             params: {
               superset_exercise: {
                 exercise_id: existing_exercise.id
               }
             },
             as: :turbo_stream
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /supersets/:superset_id/superset_exercises/:id" do
    let(:superset_exercise) { superset_exercises(:push_pull_bench) }

    it "destroys the superset exercise" do
      expect {
        delete superset_superset_exercise_path(superset, superset_exercise),
               as: :turbo_stream
      }.to change(SupersetExercise, :count).by(-1)
    end

    it "reorders remaining exercises" do
      second_exercise = superset_exercises(:push_pull_pullup)
      delete superset_superset_exercise_path(superset, superset_exercise),
             as: :turbo_stream
      expect(second_exercise.reload.position).to eq(1)
    end
  end

  describe "PATCH /supersets/:superset_id/superset_exercises/:id/move" do
    let(:superset_exercise) { superset_exercises(:push_pull_bench) }

    it "moves exercise to new position" do
      patch move_superset_superset_exercise_path(superset, superset_exercise),
            params: {
              position: 2
            }
      expect(superset_exercise.reload.position).to eq(2)
    end
  end
end
