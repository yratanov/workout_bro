describe GenerateWeeklyReportJob do
  fixtures :all

  let(:user) do
    users(:john).tap do |u|
      u.update!(
        ai_provider: "gemini",
        ai_model: "gemini-2.0-flash",
        ai_api_key: "test-key"
      )
    end
  end

  let(:ai_trainer) do
    user.ai_trainer.tap do |t|
      t.update!(
        status: :completed,
        summary: "A motivational trainer.",
        system_prompt: "You are a fitness trainer."
      )
    end
  end

  let(:week_start) { Date.current.beginning_of_week }
  let(:report_response) { "Great progress this week!" }

  before { ai_trainer }

  describe "#perform" do
    it "creates a completed ai_trainer_activity" do
      mock_service =
        instance_double(AiWeeklyReportService, call: report_response)
      allow(AiWeeklyReportService).to receive(:new).and_return(mock_service)
      allow(AiConversationBuilder).to receive(:new).and_return(
        instance_double(AiConversationBuilder, compaction_needed?: false)
      )

      described_class.new.perform(user: user, week_start: week_start)

      activity =
        user.ai_trainer_activities.weekly_report.order(created_at: :desc).first
      expect(activity).to be_completed
      expect(activity.content).to eq(report_response)
      expect(activity.week_start).to eq(week_start)
    end

    it "triggers compaction when conversation exceeds token threshold" do
      mock_service =
        instance_double(AiWeeklyReportService, call: report_response)
      allow(AiWeeklyReportService).to receive(:new).and_return(mock_service)
      allow(AiConversationBuilder).to receive(:new).and_return(
        instance_double(AiConversationBuilder, compaction_needed?: true)
      )

      expect {
        described_class.new.perform(user: user, week_start: week_start)
      }.to have_enqueued_job(GenerateFullReviewJob)
    end

    it "does not trigger compaction when under threshold" do
      mock_service =
        instance_double(AiWeeklyReportService, call: report_response)
      allow(AiWeeklyReportService).to receive(:new).and_return(mock_service)
      allow(AiConversationBuilder).to receive(:new).and_return(
        instance_double(AiConversationBuilder, compaction_needed?: false)
      )

      expect {
        described_class.new.perform(user: user, week_start: week_start)
      }.not_to have_enqueued_job(GenerateFullReviewJob)
    end

    it "marks activity as failed on error" do
      allow(AiWeeklyReportService).to receive(:new).and_raise(
        StandardError,
        "API error"
      )

      described_class.new.perform(user: user, week_start: week_start)

      activity = user.ai_trainer_activities.weekly_report.last
      expect(activity).to be_failed
      expect(activity.error_message).to eq("API error")
    end
  end
end
