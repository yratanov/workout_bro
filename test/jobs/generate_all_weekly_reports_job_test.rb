require "test_helper"

class GenerateAllWeeklyReportsJobTest < ActiveJob::TestCase
  setup do
    @john = users(:john)
    @jane = users(:jane)
  end

  test "skips users without AI configured" do
    @john.update!(ai_provider: nil, ai_model: nil, ai_api_key: nil)
    @john.ai_trainer.update!(status: :completed, trainer_profile: "Profile")

    GenerateAllWeeklyReportsJob.new.perform

    assert_enqueued_jobs 0, only: GenerateWeeklyReportJob
  end

  test "skips users without completed trainer" do
    @john.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    @john.ai_trainer.update!(status: :pending)

    GenerateAllWeeklyReportsJob.new.perform

    assert_enqueued_jobs 0, only: GenerateWeeklyReportJob
  end

  test "skips users without ai trainer" do
    @jane.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    # jane has no ai_trainer fixture

    GenerateAllWeeklyReportsJob.new.perform

    assert_enqueued_jobs 0, only: GenerateWeeklyReportJob
  end

  test "skips users without workouts in the past week" do
    @john.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    @john.ai_trainer.update!(status: :completed, trainer_profile: "Profile")
    # Move all of john's workouts to long ago
    @john.workouts.update_all(ended_at: 30.days.ago)

    GenerateAllWeeklyReportsJob.new.perform

    assert_enqueued_jobs 0, only: GenerateWeeklyReportJob
  end

  test "enqueues job for eligible users with workouts in the past week" do
    @john.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    @john.ai_trainer.update!(status: :completed, trainer_profile: "Profile")

    week_start = Date.current.beginning_of_week(:monday) - 7.days
    @john.workouts.first.update!(ended_at: week_start + 2.days)

    assert_enqueued_with(job: GenerateWeeklyReportJob) do
      GenerateAllWeeklyReportsJob.new.perform
    end
  end
end
