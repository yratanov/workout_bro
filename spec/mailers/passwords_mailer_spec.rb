describe PasswordsMailer do
  fixtures :users

  let(:user) { users(:john) }

  describe "#reset" do
    let(:mail) { described_class.reset(user) }

    it "renders the subject" do
      expect(mail.subject).to eq("Reset your password")
    end

    it "sends to the user's email" do
      expect(mail.to).to eq([user.email_address])
    end

    it "renders the sender email" do
      expect(mail.from).to eq(["from@example.com"])
    end

    it "includes the password reset link in the body" do
      expect(mail.body.encoded).to include("password")
    end
  end
end
