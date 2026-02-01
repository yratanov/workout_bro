describe "Supersets" do
  fixtures :users, :exercises, :supersets, :superset_exercises

  let(:user) { users(:john) }
  let(:superset) { supersets(:push_pull) }

  before { sign_in(user) }

  describe "GET /supersets" do
    it "returns success" do
      get supersets_path
      expect(response).to have_http_status(:success)
    end

    it "shows user's supersets" do
      get supersets_path
      expect(response.body).to include(superset.name)
    end
  end

  describe "GET /supersets/:id" do
    it "returns success" do
      get superset_path(superset)
      expect(response).to have_http_status(:success)
    end

    it "shows superset details" do
      get superset_path(superset)
      expect(response.body).to include(superset.name)
    end

    it "shows exercises in the superset" do
      get superset_path(superset)
      superset.exercises.each do |exercise|
        expect(response.body).to include(exercise.name)
      end
    end
  end

  describe "GET /supersets/new" do
    it "returns success" do
      get new_superset_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /supersets" do
    context "with valid params" do
      it "creates a new superset" do
        expect {
          post supersets_path, params: { superset: { name: "New Superset" } }
        }.to change(Superset, :count).by(1)
      end

      it "redirects to the new superset" do
        post supersets_path, params: { superset: { name: "New Superset" } }
        expect(response).to redirect_to(Superset.last)
      end
    end

    context "with invalid params" do
      it "returns unprocessable entity" do
        post supersets_path, params: { superset: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /supersets/:id/edit" do
    it "returns success" do
      get edit_superset_path(superset)
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /supersets/:id" do
    context "with valid params" do
      it "updates the superset" do
        patch superset_path(superset),
              params: {
                superset: {
                  name: "Updated Name"
                }
              }
        expect(superset.reload.name).to eq("Updated Name")
      end

      it "redirects to the superset" do
        patch superset_path(superset),
              params: {
                superset: {
                  name: "Updated Name"
                }
              }
        expect(response).to redirect_to(superset)
      end
    end

    context "with invalid params" do
      it "returns unprocessable entity" do
        patch superset_path(superset), params: { superset: { name: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /supersets/:id" do
    it "destroys the superset" do
      superset_to_delete = user.supersets.create!(name: "Deletable")
      expect { delete superset_path(superset_to_delete) }.to change(
        Superset,
        :count
      ).by(-1)
    end

    it "redirects to index" do
      delete superset_path(superset)
      expect(response).to redirect_to(supersets_path)
    end
  end

  describe "user scoping" do
    let(:other_user) { users(:jane) }
    let(:other_superset) do
      other_user.supersets.create!(name: "Other User Superset")
    end

    it "does not show other user's supersets" do
      get supersets_path
      expect(response.body).not_to include(other_superset.name)
    end

    it "returns not found for other user's superset" do
      get superset_path(other_superset)
      expect(response).to have_http_status(:not_found)
    end
  end
end
