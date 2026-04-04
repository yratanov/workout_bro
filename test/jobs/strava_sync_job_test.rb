require "test_helper"

class StravaSyncJobTest < ActiveJob::TestCase
  private

  def john
    users(:john)
  end

  def jane
    users(:jane)
  end

  test "calls StravaSyncService for user with strava credentials" do
    john.strava_credential.update!(
      access_token: "token",
      refresh_token: "refresh",
      token_expires_at: 1.hour.from_now
    )

    service = mock("strava_sync_service")
    service.expects(:call).returns({ imported: 1, skipped: 0 })
    StravaSyncService.expects(:new).with(user: john).returns(service)

    StravaSyncJob.perform_now
  end

  test "skips user without oauth tokens" do
    StravaSyncService.expects(:new).never

    StravaSyncJob.perform_now
  end

  test "logs the error and continues without raising" do
    john.strava_credential.update!(
      access_token: "token",
      refresh_token: "refresh",
      token_expires_at: 1.hour.from_now
    )

    service = mock("strava_sync_service")
    service.expects(:call).raises(StravaSyncService::Error, "Sync failed")
    StravaSyncService.stubs(:new).returns(service)

    assert_nothing_raised { StravaSyncJob.perform_now }
  end

  test "syncs all users with strava credentials" do
    john.strava_credential.update!(
      access_token: "token1",
      refresh_token: "refresh1",
      token_expires_at: 1.hour.from_now
    )
    jane.strava_credential.update!(
      access_token: "token2",
      refresh_token: "refresh2",
      token_expires_at: 1.hour.from_now
    )

    service = mock("strava_sync_service")
    service.stubs(:call).returns({ imported: 0, skipped: 0 })
    StravaSyncService.expects(:new).with(user: john).returns(service)
    StravaSyncService.expects(:new).with(user: jane).returns(service)

    StravaSyncJob.perform_now
  end
end
