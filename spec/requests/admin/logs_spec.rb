describe "Admin::Logs" do
  fixtures :all

  let(:admin_user) { users(:john) }
  let(:regular_user) { users(:jane) }

  describe "as admin" do
    before { sign_in(admin_user) }

    describe "GET /admin/logs" do
      it "returns success" do
        get admin_logs_path
        expect(response).to have_http_status(:success)
      end

      it "displays the error logs page" do
        get admin_logs_path
        expect(response.body).to include(I18n.t("admin.logs.show.error_logs"))
      end

      it "displays error logs when present" do
        ErrorLog.create!(
          error_class: "StandardError",
          message: "Test error message",
          severity: :error,
          source: "test"
        )

        get admin_logs_path
        expect(response.body).to include("StandardError")
        expect(response.body).to include("Test error message")
      end

      it "displays error logs in descending order by created_at" do
        ErrorLog.create!(
          error_class: "OldError",
          message: "Old error",
          severity: :error,
          created_at: 1.hour.ago
        )
        ErrorLog.create!(
          error_class: "NewError",
          message: "New error",
          severity: :error,
          created_at: Time.current
        )

        get admin_logs_path
        expect(response.body.index("NewError")).to be <
          response.body.index("OldError")
      end

      it "displays severity badge" do
        ErrorLog.create!(
          error_class: "TestError",
          message: "Test",
          severity: :error
        )

        get admin_logs_path
        expect(response.body).to include(
          I18n.t("admin.logs.show.severities.error")
        )
      end

      it "displays source when present" do
        ErrorLog.create!(
          error_class: "TestError",
          message: "Test",
          severity: :error,
          source: "custom_source"
        )

        get admin_logs_path
        expect(response.body).to include("custom_source")
      end

      it "displays backtrace toggle when backtrace present" do
        ErrorLog.create!(
          error_class: "TestError",
          message: "Test",
          severity: :error,
          backtrace: %w[/app/test.rb:1 /app/test.rb:2]
        )

        get admin_logs_path
        expect(response.body).to include(
          I18n.t("admin.logs.show.show_backtrace")
        )
        expect(response.body).to include("/app/test.rb:1")
      end

      it "shows empty state when no logs" do
        get admin_logs_path
        expect(response.body).to include(I18n.t("admin.logs.show.no_logs"))
      end

      it "limits to 100 logs" do
        105.times do |i|
          ErrorLog.create!(
            error_class: "Error#{i}",
            message: "Message #{i}",
            severity: :error
          )
        end

        get admin_logs_path
        # Should not include the oldest errors (0-4)
        expect(response.body).not_to include("Error0")
        # Should include the newest errors
        expect(response.body).to include("Error104")
      end
    end
  end

  describe "as regular user" do
    before { sign_in(regular_user) }

    it "redirects from GET /admin/logs" do
      get admin_logs_path
      expect(response).to redirect_to(root_path)
    end

    it "shows admin required flash message" do
      get admin_logs_path
      follow_redirect!
      expect(response.body).to include(
        I18n.t("controllers.application.admin_required")
      )
    end
  end

  describe "when not authenticated" do
    it "redirects to login" do
      get admin_logs_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
