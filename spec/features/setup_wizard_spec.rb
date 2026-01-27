describe "Setup Wizard" do
  before do
    Capybara.reset_sessions!
  end

  describe "fresh installation (no users)", fixtures: false do
    before do
      conn = ActiveRecord::Base.connection
      conn.disable_referential_integrity do
        conn.tables.each do |table|
          next if table == "schema_migrations" || table == "ar_internal_metadata"

          conn.execute("DELETE FROM #{table}")
        end
      end
    end

    it "redirects to setup wizard from root" do
      visit root_path
      expect(page).to have_current_path(setup_path)
    end

    it "shows the account creation step" do
      visit setup_path
      expect(page).to have_content(I18n.t("setup.account.title"))
      expect(page).to have_field("user_email_address")
      expect(page).to have_field("user_password")
    end

    it "completes full wizard flow" do
      visit setup_path

      # Step 1: Create account
      expect(page).to have_content(I18n.t("setup.account.title"))
      fill_in "user_email_address", with: "test@example.com"
      fill_in "user_password", with: "password123"
      fill_in "user_password_confirmation", with: "password123"
      click_button I18n.t("setup.account.next")

      # Step 2: Select language
      expect(page).to have_content(I18n.t("setup.language.title"))
      click_button I18n.t("setup.language.next")

      # Step 3: Exercises
      expect(page).to have_content(I18n.t("setup.exercises.title"))
      click_button I18n.t("setup.exercises.skip_button")

      # Step 4: Garmin (skip)
      expect(page).to have_content(I18n.t("setup.garmin.title"))
      click_button I18n.t("setup.garmin.skip_button")

      # Step 5: Complete
      expect(page).to have_content(I18n.t("setup.complete.title"))
      click_button I18n.t("setup.complete.start_workout")

      expect(page).to have_current_path(new_workout_path)
      expect(page).to have_content(I18n.t("controllers.setup.completed"))
    end

    it "advances to garmin step when importing exercises" do
      visit setup_path

      # Step 1: Create account
      fill_in "user_email_address", with: "test@example.com"
      fill_in "user_password", with: "password123"
      fill_in "user_password_confirmation", with: "password123"
      click_button I18n.t("setup.account.next")

      # Step 2: Select language
      click_button I18n.t("setup.language.next")

      # Step 3: Import exercises
      click_button I18n.t("setup.exercises.import_button")

      # Should advance to Garmin step
      expect(page).to have_content(I18n.t("setup.garmin.title"))
    end

    it "shows validation errors on account creation" do
      visit setup_path

      fill_in "user_email_address", with: "test@example.com"
      fill_in "user_password", with: "password123"
      fill_in "user_password_confirmation", with: "different"
      click_button I18n.t("setup.account.next")

      expect(page).to have_current_path(setup_path)
      expect(page).to have_content(I18n.t("setup.account.title"))
    end
  end

  describe "resuming wizard" do
    let!(:user) { User.create!(email_address: "test@example.com", password: "password", setup_completed: true, wizard_step: 4) }

    it "redirects incomplete setup users to wizard" do
      user.update!(setup_completed: false, wizard_step: 2)

      login_as(user)

      expect(page).to have_current_path(setup_path)
      expect(page).to have_content(I18n.t("setup.exercises.title"))
    end

    it "allows completed users to access the app normally" do
      login_as(user)

      expect(page).to have_current_path(root_path)
    end
  end
end
