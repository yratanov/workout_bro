require "test_helper"

class GarminSyncJobTest < ActiveJob::TestCase
  private

  def john
    users(:john)
  end

  def jane
    users(:jane)
  end

  test "calls GarminSyncService for user with garmin credentials" do
    john.garmin_credential.update!(
      username: "garmin_user",
      password: "secret123"
    )

    service = mock("garmin_sync_service")
    service.expects(:call).returns({ imported: 1, skipped: 0 })
    GarminSyncService.expects(:new).with(user: john).returns(service)

    GarminSyncJob.perform_now
  end

  test "skips user with blank username" do
    john.garmin_credential.update!(username: "", password: "secret123")

    GarminSyncService.expects(:new).never

    GarminSyncJob.perform_now
  end

  test "skips user with blank encrypted_password" do
    john.garmin_credential.update!(username: "garmin_user")

    GarminSyncService.expects(:new).never

    GarminSyncJob.perform_now
  end

  test "logs the error and continues without raising" do
    john.garmin_credential.update!(
      username: "garmin_user",
      password: "secret123"
    )

    service = mock("garmin_sync_service")
    service.expects(:call).raises(GarminSyncService::Error, "Sync failed")
    GarminSyncService.stubs(:new).returns(service)

    assert_nothing_raised { GarminSyncJob.perform_now }
  end

  test "syncs all users with credentials" do
    john.garmin_credential.update!(username: "john_garmin", password: "pass1")
    jane.garmin_credential.update!(username: "jane_garmin", password: "pass2")

    service = mock("garmin_sync_service")
    service.stubs(:call).returns({ imported: 0, skipped: 0 })
    GarminSyncService.expects(:new).with(user: john).returns(service)
    GarminSyncService.expects(:new).with(user: jane).returns(service)

    GarminSyncJob.perform_now
  end

  test "continues processing remaining users after a failure" do
    john.garmin_credential.update!(username: "john_garmin", password: "pass1")
    jane.garmin_credential.update!(username: "jane_garmin", password: "pass2")

    failing_service = mock("failing_service")
    failing_service.expects(:call).raises(GarminSyncService::Error, "Failed")

    success_service = mock("success_service")
    success_service.expects(:call).returns({ imported: 1, skipped: 0 })

    GarminSyncService
      .stubs(:new)
      .returns(failing_service)
      .then
      .returns(success_service)

    assert_nothing_raised { GarminSyncJob.perform_now }
  end
end
