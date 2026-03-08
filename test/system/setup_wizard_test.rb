require "application_system_test_case"

class SetupWizardTest < ApplicationSystemTestCase
  setup { Capybara.reset_sessions! }

  # --- Fresh installation (no users) tests ---

  private def clear_all_tables
    conn = ActiveRecord::Base.connection
    conn.disable_referential_integrity do
      conn.tables.each do |table|
        next if table == "schema_migrations" || table == "ar_internal_metadata"
        conn.execute("DELETE FROM #{table}")
      end
    end
  end

  test "fresh install redirects to setup wizard from root" do
    clear_all_tables

    visit root_path
    assert_current_path setup_path
  end

  test "fresh install shows the account creation step" do
    clear_all_tables

    visit setup_path
    assert_text I18n.t("setup.account.title")
    assert_field "user_first_name"
    assert_field "user_last_name"
    assert_field "user_email"
    assert_field "user_password"
  end

  test "fresh install completes full wizard flow" do
    clear_all_tables

    visit setup_path

    # Step 1: Create account
    assert_text I18n.t("setup.account.title")
    fill_in "user_first_name", with: "Test"
    fill_in "user_last_name", with: "User"
    fill_in "user_email", with: "test@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"
    click_button I18n.t("setup.account.next")

    # Step 2: Select language
    assert_text I18n.t("setup.language.title")
    click_button I18n.t("setup.language.next")

    # Step 3: Exercises
    assert_text I18n.t("setup.exercises.title")
    click_button I18n.t("setup.exercises.skip_button")

    # Step 4: Garmin (skip)
    assert_text I18n.t("setup.garmin.title")
    click_button I18n.t("setup.garmin.skip_button")

    # Step 5: Complete
    assert_text I18n.t("setup.complete.title")
    click_button I18n.t("setup.complete.start_workout")

    assert_current_path new_workout_path
    assert_text I18n.t("controllers.setup.completed")
  end

  test "fresh install advances to garmin step when importing exercises" do
    clear_all_tables

    visit setup_path

    # Step 1: Create account
    fill_in "user_first_name", with: "Test"
    fill_in "user_last_name", with: "User"
    fill_in "user_email", with: "test@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "password123"
    click_button I18n.t("setup.account.next")

    # Step 2: Select language
    click_button I18n.t("setup.language.next")

    # Step 3: Import exercises
    click_button I18n.t("setup.exercises.import_button")

    # Should advance to Garmin step
    assert_text I18n.t("setup.garmin.title")
  end

  test "fresh install shows validation errors on account creation" do
    clear_all_tables

    visit setup_path

    fill_in "user_first_name", with: "Test"
    fill_in "user_last_name", with: "User"
    fill_in "user_email", with: "test@example.com"
    fill_in "user_password", with: "password123"
    fill_in "user_password_confirmation", with: "different"
    click_button I18n.t("setup.account.next")

    assert_current_path setup_path
    assert_text I18n.t("setup.account.title")
  end

  # --- Resuming wizard tests ---

  test "redirects incomplete setup users to wizard" do
    user =
      User.create!(
        email: "test_resume@example.com",
        password: "password",
        setup_completed: false,
        wizard_step: 2
      )

    login_as(user)

    assert_current_path setup_path
    assert_text I18n.t("setup.exercises.title")
  end

  test "allows completed users to access the app normally" do
    user =
      User.create!(
        email: "test_complete@example.com",
        password: "password",
        setup_completed: true,
        wizard_step: 4
      )

    login_as(user)

    assert_current_path root_path
  end
end
