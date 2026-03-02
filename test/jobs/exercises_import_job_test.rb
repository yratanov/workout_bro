require "test_helper"

class ExercisesImportJobTest < ActiveJob::TestCase
  test "calls ExercisesImporter with the given user" do
    user = users(:john)
    mock_importer = mock("importer")
    mock_importer.expects(:call).once

    ExercisesImporter.expects(:new).with(user: user).returns(mock_importer)

    ExercisesImportJob.new.perform(user: user)
  end
end
