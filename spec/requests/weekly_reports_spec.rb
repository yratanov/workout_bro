describe "WeeklyReports" do
  fixtures :users, :weekly_reports

  let(:user) { users(:john) }

  describe "GET /weekly_reports" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns success" do
        get weekly_reports_path
        expect(response).to have_http_status(:success)
      end

      it "shows the user's reports" do
        get weekly_reports_path
        expect(response.body).to include("Completed")
        expect(response.body).to include("Pending")
      end

      it "does not show other users' reports" do
        get weekly_reports_path
        expect(response.body).not_to include("Good progress this week")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get weekly_reports_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /weekly_reports/:id" do
    context "when authenticated" do
      before { sign_in(user) }

      it "shows the report with AI summary" do
        report = weekly_reports(:johns_completed_report)
        get weekly_report_path(report)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Great training week")
      end

      it "marks the report as viewed" do
        report = weekly_reports(:johns_completed_report)
        expect(report.viewed_at).to be_nil

        get weekly_report_path(report)

        report.reload
        expect(report.viewed_at).to be_present
      end

      it "does not update viewed_at if already viewed" do
        report = weekly_reports(:johns_completed_report)
        original_time = 1.hour.ago
        report.update!(viewed_at: original_time)

        get weekly_report_path(report)

        report.reload
        expect(report.viewed_at).to be_within(1.second).of(original_time)
      end

      it "shows pending state" do
        report = weekly_reports(:johns_pending_report)
        get weekly_report_path(report)
        expect(response).to have_http_status(:success)
      end

      it "returns not found for another user's report" do
        report = weekly_reports(:janes_report)
        get weekly_report_path(report)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
