require "test_helper"

class GenerateWeeklyReportJobTest < ActiveJob::TestCase
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )

    @ai_trainer = @user.ai_trainer
    @ai_trainer.update!(
      status: :completed,
      trainer_profile: "A motivational trainer."
    )

    @week_start = Date.current.beginning_of_week
    @report_response = "Great progress this week!"
  end

  test "creates a completed ai_trainer_activity" do
    VCR.use_cassette("jobs/weekly_report/success") do
      GenerateWeeklyReportJob.new.perform(user: @user, week_start: @week_start)
    end

    activity =
      @user.ai_trainer_activities.weekly_report.order(created_at: :desc).first
    assert activity.completed?
    assert_equal @report_response, activity.content
    assert_equal @week_start, activity.week_start
  end

  test "triggers compaction when conversation exceeds token threshold" do
    AiConversationBuilder.any_instance.stubs(:compaction_needed?).returns(true)

    assert_enqueued_with(job: GenerateFullReviewJob) do
      VCR.use_cassette("jobs/weekly_report/success") do
        GenerateWeeklyReportJob.new.perform(
          user: @user,
          week_start: @week_start
        )
      end
    end
  end

  test "does not trigger compaction when under threshold" do
    VCR.use_cassette("jobs/weekly_report/success") do
      GenerateWeeklyReportJob.new.perform(user: @user, week_start: @week_start)
    end

    assert_enqueued_jobs 0, only: GenerateFullReviewJob
  end

  test "marks activity as failed on error" do
    VCR.use_cassette("jobs/weekly_report/error") do
      GenerateWeeklyReportJob.new.perform(user: @user, week_start: @week_start)
    end

    activity = @user.ai_trainer_activities.weekly_report.last
    assert activity.failed?
    assert_not_nil activity.error_message
  end
end
