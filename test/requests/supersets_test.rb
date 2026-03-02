require "test_helper"

class SupersetsTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:john)
    @superset = supersets(:push_pull)
    sign_in(@user)
  end

  test "GET /supersets returns success" do
    get supersets_path
    assert_response :success
  end

  test "GET /supersets shows user's supersets" do
    get supersets_path
    assert_includes response.body, @superset.name
  end

  test "GET /supersets/:id returns success" do
    get superset_path(@superset)
    assert_response :success
  end

  test "GET /supersets/:id shows superset details" do
    get superset_path(@superset)
    assert_includes response.body, @superset.name
  end

  test "GET /supersets/:id shows exercises in the superset" do
    get superset_path(@superset)
    @superset.exercises.each do |exercise|
      assert_includes response.body, exercise.name
    end
  end

  test "GET /supersets/new returns success" do
    get new_superset_path
    assert_response :success
  end

  test "POST /supersets with valid params creates a new superset" do
    assert_difference "Superset.count", 1 do
      post supersets_path, params: { superset: { name: "New Superset" } }
    end
  end

  test "POST /supersets with valid params redirects to the new superset" do
    post supersets_path, params: { superset: { name: "New Superset" } }
    assert_redirected_to Superset.last
  end

  test "POST /supersets with invalid params returns unprocessable entity" do
    post supersets_path, params: { superset: { name: "" } }
    assert_response :unprocessable_content
  end

  test "GET /supersets/:id/edit returns success" do
    get edit_superset_path(@superset)
    assert_response :success
  end

  test "PATCH /supersets/:id with valid params updates the superset" do
    patch superset_path(@superset),
          params: {
            superset: {
              name: "Updated Name"
            }
          }
    assert_equal "Updated Name", @superset.reload.name
  end

  test "PATCH /supersets/:id with valid params redirects to the superset" do
    patch superset_path(@superset),
          params: {
            superset: {
              name: "Updated Name"
            }
          }
    assert_redirected_to @superset
  end

  test "PATCH /supersets/:id with invalid params returns unprocessable entity" do
    patch superset_path(@superset), params: { superset: { name: "" } }
    assert_response :unprocessable_content
  end

  test "DELETE /supersets/:id destroys the superset" do
    superset_to_delete = @user.supersets.create!(name: "Deletable")
    assert_difference "Superset.count", -1 do
      delete superset_path(superset_to_delete)
    end
  end

  test "DELETE /supersets/:id redirects to index" do
    delete superset_path(@superset)
    assert_redirected_to supersets_path
  end

  test "GET /supersets does not show other user's supersets" do
    other_user = users(:jane)
    other_superset = other_user.supersets.create!(name: "Other User Superset")
    get supersets_path
    assert_not_includes response.body, other_superset.name
  end

  test "GET /supersets/:id returns not found for other user's superset" do
    other_user = users(:jane)
    other_superset = other_user.supersets.create!(name: "Other User Superset")
    get superset_path(other_superset)
    assert_response :not_found
  end
end
