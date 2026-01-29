describe "Exercises" do
  fixtures :users, :exercises, :muscles

  let(:user) { users(:john) }
  let(:exercise) { exercises(:pull_up) }
  let(:muscle) { muscles(:chest) }

  before { sign_in(user) }

  describe "GET /exercises" do
    it "returns success" do
      get exercises_path
      expect(response).to have_http_status(:success)
    end

    it "shows user's exercises" do
      get exercises_path
      expect(response.body).to include(exercise.name)
    end
  end

  describe "GET /exercises/:id" do
    it "returns success" do
      get exercise_path(exercise)
      expect(response).to have_http_status(:success)
    end

    it "shows exercise details" do
      get exercise_path(exercise)
      expect(response.body).to include(exercise.name)
    end
  end

  describe "GET /exercises/new" do
    it "returns success" do
      get new_exercise_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /exercises" do
    context "with valid params" do
      it "creates a new exercise" do
        expect {
          post exercises_path,
               params: {
                 exercise: {
                   name: "New Exercise",
                   muscle_id: muscle.id,
                   with_weights: true,
                   with_band: false
                 }
               }
        }.to change(Exercise, :count).by(1)
      end

      it "redirects to the new exercise" do
        post exercises_path,
             params: {
               exercise: {
                 name: "New Exercise",
                 muscle_id: muscle.id,
                 with_weights: true,
                 with_band: false
               }
             }
        expect(response).to redirect_to(Exercise.last)
      end
    end

    context "with invalid params" do
      before do
        allow_any_instance_of(Exercise).to receive(:save).and_return(false)
      end

      it "returns unprocessable entity" do
        post exercises_path, params: { exercise: { name: "Test" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /exercises/:id/edit" do
    it "returns success" do
      get edit_exercise_path(exercise)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /exercises/:id" do
    context "with valid params" do
      it "updates the exercise" do
        patch exercise_path(exercise),
              params: {
                exercise: {
                  name: "Updated Name"
                }
              }
        expect(exercise.reload.name).to eq("Updated Name")
      end

      it "redirects to the exercise" do
        patch exercise_path(exercise),
              params: {
                exercise: {
                  name: "Updated Name"
                }
              }
        expect(response).to redirect_to(exercise)
      end
    end

    context "with invalid params" do
      before do
        allow_any_instance_of(Exercise).to receive(:update).and_return(false)
      end

      it "returns unprocessable entity" do
        patch exercise_path(exercise), params: { exercise: { name: "Test" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /exercises/:id" do
    let(:deletable_exercise) do
      user.exercises.create!(name: "Deletable Exercise", muscle: muscle)
    end

    it "destroys the exercise" do
      deletable_exercise
      expect { delete exercise_path(deletable_exercise) }.to change(
        Exercise,
        :count
      ).by(-1)
    end

    it "redirects to index" do
      delete exercise_path(deletable_exercise)
      expect(response).to redirect_to(exercises_path)
    end
  end
end
