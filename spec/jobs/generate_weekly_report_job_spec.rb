describe GenerateWeeklyReportJob do
  fixtures :users, :ai_trainers

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
  let(:report_response) do
    "Great progress this week!\n\n## Week of Jan 1\n**Strengths**: Good consistency\n**Areas**: Rest more"
  end

  before { ai_trainer }

  describe "#perform" do
    it "creates a completed weekly report" do
      mock_service =
        instance_double(AiWeeklyReportService, call: report_response)
      allow(AiWeeklyReportService).to receive(:new).and_return(mock_service)

      described_class.new.perform(user: user, week_start: week_start)

      report = user.weekly_reports.find_by(week_start: week_start)
      expect(report).to be_completed
      expect(report.ai_summary).to eq(report_response)
    end

    it "appends weekly recommendations to ai_trainer system_prompt" do
      mock_service =
        instance_double(AiWeeklyReportService, call: report_response)
      allow(AiWeeklyReportService).to receive(:new).and_return(mock_service)

      described_class.new.perform(user: user, week_start: week_start)

      expect(ai_trainer.reload.system_prompt).to include("## Week of Jan 1")
    end

    it "does not append when response has no ## Week section" do
      response_without_week = "Great progress this week! Keep it up."
      mock_service =
        instance_double(AiWeeklyReportService, call: response_without_week)
      allow(AiWeeklyReportService).to receive(:new).and_return(mock_service)

      expect {
        described_class.new.perform(user: user, week_start: week_start)
      }.not_to change { ai_trainer.reload.system_prompt }
    end

    it "triggers compaction after 4 weekly sections accumulate" do
      weeks = (1..3).map { |i| "## Week #{i}\nNotes" }.join("\n\n")
      ai_trainer.update!(system_prompt: "Base prompt\n\n#{weeks}")

      mock_service =
        instance_double(AiWeeklyReportService, call: report_response)
      allow(AiWeeklyReportService).to receive(:new).and_return(mock_service)

      compactor = instance_double(AiTrainerPromptCompactor)
      allow(AiTrainerPromptCompactor).to receive(:new).and_return(compactor)
      allow(compactor).to receive(:call)

      described_class.new.perform(user: user, week_start: week_start)

      expect(AiTrainerPromptCompactor).to have_received(:new).with(ai_trainer)
      expect(compactor).to have_received(:call)
    end

    it "does not call AI when below compaction threshold" do
      mock_service =
        instance_double(AiWeeklyReportService, call: report_response)
      allow(AiWeeklyReportService).to receive(:new).and_return(mock_service)

      original_prompt = ai_trainer.system_prompt

      expect(GeminiClient).not_to receive(:new)

      described_class.new.perform(user: user, week_start: week_start)

      # Prompt was appended to but not compacted
      updated_prompt = ai_trainer.reload.system_prompt
      expect(updated_prompt).to start_with(original_prompt)
      expect(updated_prompt).to include("## Week of Jan 1")
    end

    it "marks report as failed on error" do
      allow(AiWeeklyReportService).to receive(:new).and_raise(
        StandardError,
        "API error"
      )

      described_class.new.perform(user: user, week_start: week_start)

      report = user.weekly_reports.find_by(week_start: week_start)
      expect(report).to be_failed
      expect(report.error_message).to eq("API error")
    end
  end
end
