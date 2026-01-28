describe GarminSyncJob do
  fixtures :users

  let(:john) { users(:john) }
  let(:jane) { users(:jane) }

  describe "#perform" do
    context "when user has garmin credentials" do
      before do
        john.garmin_credential.update!(
          username: "garmin_user",
          password: "secret123"
        )
      end

      it "calls GarminSyncService for the user" do
        service =
          instance_double(GarminSyncService, call: { imported: 1, skipped: 0 })
        allow(GarminSyncService).to receive(:new).and_return(service)

        described_class.perform_now

        expect(GarminSyncService).to have_received(:new).with(user: john)
        expect(service).to have_received(:call)
      end
    end

    context "when user has blank username" do
      before do
        john.garmin_credential.update!(username: "", password: "secret123")
      end

      it "skips the user" do
        allow(GarminSyncService).to receive(:new)

        described_class.perform_now

        expect(GarminSyncService).not_to have_received(:new)
      end
    end

    context "when user has blank encrypted_password" do
      it "skips the user" do
        # garmin_credential initialized without password has nil encrypted_password
        john.garmin_credential.update!(username: "garmin_user")

        allow(GarminSyncService).to receive(:new)

        described_class.perform_now

        expect(GarminSyncService).not_to have_received(:new)
      end
    end

    context "when GarminSyncService raises an error" do
      before do
        john.garmin_credential.update!(
          username: "garmin_user",
          password: "secret123"
        )
      end

      it "logs the error and continues without raising" do
        service = instance_double(GarminSyncService)
        allow(service).to receive(:call).and_raise(
          GarminSyncService::Error,
          "Sync failed"
        )
        allow(GarminSyncService).to receive(:new).and_return(service)

        expect { described_class.perform_now }.not_to raise_error
      end
    end

    context "with multiple users" do
      before do
        john.garmin_credential.update!(
          username: "john_garmin",
          password: "pass1"
        )
        jane.garmin_credential.update!(
          username: "jane_garmin",
          password: "pass2"
        )
      end

      it "syncs all users with credentials" do
        service =
          instance_double(GarminSyncService, call: { imported: 0, skipped: 0 })
        allow(GarminSyncService).to receive(:new).and_return(service)

        described_class.perform_now

        expect(GarminSyncService).to have_received(:new).with(user: john)
        expect(GarminSyncService).to have_received(:new).with(user: jane)
      end
    end

    context "when one user fails and another succeeds" do
      before do
        john.garmin_credential.update!(
          username: "john_garmin",
          password: "pass1"
        )
        jane.garmin_credential.update!(
          username: "jane_garmin",
          password: "pass2"
        )
      end

      it "continues processing remaining users after a failure" do
        failing_service = instance_double(GarminSyncService)
        allow(failing_service).to receive(:call).and_raise(
          GarminSyncService::Error,
          "Failed"
        )

        success_service =
          instance_double(GarminSyncService, call: { imported: 1, skipped: 0 })

        allow(GarminSyncService).to receive(:new).and_return(
          failing_service,
          success_service
        )

        expect { described_class.perform_now }.not_to raise_error
        expect(GarminSyncService).to have_received(:new).twice
      end
    end
  end
end
