describe ErrorLog do
  fixtures :all

  describe "validations" do
    it "is valid with valid attributes" do
      error_log = ErrorLog.new(
        error_class: "StandardError",
        message: "Test error",
        severity: :error
      )
      expect(error_log).to be_valid
    end

    it "requires error_class" do
      error_log = ErrorLog.new(
        message: "Test error",
        severity: :error
      )
      expect(error_log).not_to be_valid
      expect(error_log.errors[:error_class]).to include("can't be blank")
    end

    it "requires severity" do
      error_log = ErrorLog.new(
        error_class: "StandardError",
        message: "Test error",
        severity: nil
      )
      expect(error_log).not_to be_valid
    end
  end

  describe "enums" do
    it "defines severity enum" do
      expect(ErrorLog.severities).to eq({ "error" => 0, "warning" => 1, "info" => 2 })
    end

    it "allows setting severity to error" do
      error_log = ErrorLog.new(severity: :error)
      expect(error_log.error?).to be true
    end

    it "allows setting severity to warning" do
      error_log = ErrorLog.new(severity: :warning)
      expect(error_log.warning?).to be true
    end

    it "allows setting severity to info" do
      error_log = ErrorLog.new(severity: :info)
      expect(error_log.info?).to be true
    end
  end

  describe "scopes" do
    describe ".recent" do
      it "orders by created_at descending" do
        old_log = ErrorLog.create!(error_class: "Old", severity: :error, created_at: 1.hour.ago)
        new_log = ErrorLog.create!(error_class: "New", severity: :error, created_at: Time.current)

        expect(ErrorLog.recent.first).to eq(new_log)
        expect(ErrorLog.recent.last).to eq(old_log)
      end
    end
  end

  describe "defaults" do
    it "defaults severity to error" do
      error_log = ErrorLog.new(error_class: "Test")
      expect(error_log.severity).to eq("error")
    end

    it "defaults source to application" do
      error_log = ErrorLog.create!(error_class: "Test", severity: :error)
      expect(error_log.source).to eq("application")
    end
  end

  describe "json fields" do
    it "stores backtrace as array" do
      error_log = ErrorLog.create!(
        error_class: "StandardError",
        severity: :error,
        backtrace: [ "/app/file.rb:1", "/app/file.rb:2" ]
      )
      error_log.reload
      expect(error_log.backtrace).to eq([ "/app/file.rb:1", "/app/file.rb:2" ])
    end

    it "stores context as hash" do
      error_log = ErrorLog.create!(
        error_class: "StandardError",
        severity: :error,
        context: { user_id: 1, action: "test" }
      )
      error_log.reload
      expect(error_log.context).to eq({ "user_id" => 1, "action" => "test" })
    end
  end
end
