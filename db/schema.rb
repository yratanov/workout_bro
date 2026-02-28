# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_28_111852) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "error_logs", force: :cascade do |t|
    t.json "backtrace"
    t.json "context"
    t.datetime "created_at", null: false
    t.string "error_class", null: false
    t.text "message"
    t.string "request_id"
    t.integer "severity", default: 0, null: false
    t.string "source", default: "application"
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_error_logs_on_created_at"
    t.index ["severity"], name: "index_error_logs_on_severity"
  end

  create_table "exercises", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "muscle_id"
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.boolean "with_band", default: false, null: false
    t.boolean "with_weights", default: true, null: false
    t.index ["muscle_id"], name: "index_exercises_on_muscle_id"
    t.index ["user_id"], name: "index_exercises_on_user_id"
  end

  create_table "invites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.integer "used_by_user_id"
    t.integer "user_id", null: false
    t.index ["token"], name: "index_invites_on_token", unique: true
    t.index ["used_by_user_id"], name: "index_invites_on_used_by_user_id"
    t.index ["user_id"], name: "index_invites_on_user_id"
  end

  create_table "muscles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_muscles_on_name", unique: true
  end

  create_table "personal_records", force: :cascade do |t|
    t.date "achieved_on", null: false
    t.string "band"
    t.datetime "created_at", null: false
    t.integer "distance"
    t.integer "exercise_id"
    t.float "pace"
    t.integer "pr_type", default: 0, null: false
    t.integer "reps"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.float "volume"
    t.float "weight"
    t.integer "workout_id", null: false
    t.integer "workout_rep_id"
    t.index ["exercise_id"], name: "index_personal_records_on_exercise_id"
    t.index ["user_id", "exercise_id", "pr_type", "band"], name: "index_prs_on_user_exercise_type_band"
    t.index ["workout_id"], name: "index_personal_records_on_workout_id"
    t.index ["workout_rep_id"], name: "index_personal_records_on_workout_rep_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth", null: false
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.datetime "last_used_at"
    t.string "p256dh", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id", "endpoint"], name: "index_push_subscriptions_on_user_id_and_endpoint", unique: true
  end

  create_table "scheduled_push_notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "job_id", null: false
    t.string "notification_type", null: false
    t.datetime "scheduled_for", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["job_id"], name: "index_scheduled_push_notifications_on_job_id", unique: true
    t.index ["user_id"], name: "index_scheduled_push_notifications_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "superset_exercises", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "exercise_id", null: false
    t.integer "position", null: false
    t.integer "superset_id", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_superset_exercises_on_exercise_id"
    t.index ["superset_id", "exercise_id"], name: "index_superset_exercises_on_superset_id_and_exercise_id", unique: true
    t.index ["superset_id", "position"], name: "index_superset_exercises_on_superset_id_and_position"
  end

  create_table "supersets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_supersets_on_user_id"
  end

  create_table "sync_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "log_type", default: 0, null: false
    t.text "message"
    t.json "metadata"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["created_at"], name: "index_sync_logs_on_created_at"
    t.index ["log_type"], name: "index_sync_logs_on_log_type"
    t.index ["status"], name: "index_sync_logs_on_status"
    t.index ["user_id"], name: "index_sync_logs_on_user_id"
  end

  create_table "third_party_credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "encrypted_password"
    t.string "provider", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.string "username"
    t.index ["user_id", "provider"], name: "index_third_party_credentials_on_user_id_and_provider", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "ai_model"
    t.string "ai_provider"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "locale", default: "en"
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.boolean "setup_completed", default: false, null: false
    t.datetime "updated_at", null: false
    t.float "weight_max", default: 100.0, null: false
    t.float "weight_min", default: 2.5, null: false
    t.float "weight_step", default: 2.5, null: false
    t.string "weight_unit", default: "kg", null: false
    t.integer "wizard_step", default: 0
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "workout_imports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "error_details"
    t.integer "imported_count", default: 0, null: false
    t.string "original_filename"
    t.integer "skipped_count", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_workout_imports_on_user_id"
  end

  create_table "workout_reps", force: :cascade do |t|
    t.string "band"
    t.datetime "created_at", null: false
    t.integer "reps", null: false
    t.datetime "updated_at", null: false
    t.float "weight"
    t.integer "workout_set_id", null: false
    t.index ["workout_set_id"], name: "index_workout_reps_on_workout_set_id"
  end

  create_table "workout_routine_day_exercises", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "exercise_id"
    t.integer "position"
    t.integer "superset_id"
    t.datetime "updated_at", null: false
    t.integer "workout_routine_day_id", null: false
    t.index ["exercise_id"], name: "index_workout_routine_day_exercises_on_exercise_id"
    t.index ["superset_id"], name: "index_workout_routine_day_exercises_on_superset_id"
    t.index ["workout_routine_day_id"], name: "index_workout_routine_day_exercises_on_workout_routine_day_id"
  end

  create_table "workout_routine_days", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "workout_routine_id", null: false
    t.index ["workout_routine_id"], name: "index_workout_routine_days_on_workout_routine_id"
  end

  create_table "workout_routines", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_workout_routines_on_user_id"
  end

  create_table "workout_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ended_at"
    t.integer "exercise_id", null: false
    t.text "notes"
    t.datetime "paused_at"
    t.datetime "started_at"
    t.integer "superset_group"
    t.integer "superset_id"
    t.integer "total_paused_seconds", default: 0
    t.datetime "updated_at", null: false
    t.integer "workout_id", null: false
    t.index ["exercise_id"], name: "index_workout_sets_on_exercise_id"
    t.index ["superset_id"], name: "index_workout_sets_on_superset_id"
    t.index ["workout_id", "superset_group"], name: "index_workout_sets_on_workout_id_and_superset_group"
  end

  create_table "workouts", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date"
    t.integer "distance"
    t.datetime "ended_at"
    t.text "notes"
    t.datetime "paused_at"
    t.datetime "started_at", null: false
    t.integer "time_in_seconds"
    t.integer "total_paused_seconds", default: 0
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "workout_import_id"
    t.integer "workout_routine_day_id"
    t.integer "workout_type", default: 0, null: false
    t.index ["user_id"], name: "index_workouts_on_user_id"
    t.index ["workout_import_id"], name: "index_workouts_on_workout_import_id"
    t.index ["workout_routine_day_id"], name: "index_workouts_on_workout_routine_day_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "exercises", "muscles", on_delete: :nullify
  add_foreign_key "exercises", "users"
  add_foreign_key "invites", "users"
  add_foreign_key "invites", "users", column: "used_by_user_id", on_delete: :nullify
  add_foreign_key "personal_records", "exercises", on_delete: :cascade
  add_foreign_key "personal_records", "users"
  add_foreign_key "personal_records", "workout_reps", on_delete: :cascade
  add_foreign_key "personal_records", "workouts", on_delete: :cascade
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "scheduled_push_notifications", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "superset_exercises", "exercises"
  add_foreign_key "superset_exercises", "supersets", on_delete: :cascade
  add_foreign_key "supersets", "users"
  add_foreign_key "sync_logs", "users"
  add_foreign_key "third_party_credentials", "users"
  add_foreign_key "workout_imports", "users"
  add_foreign_key "workout_reps", "workout_sets"
  add_foreign_key "workout_routine_day_exercises", "exercises"
  add_foreign_key "workout_routine_day_exercises", "supersets", on_delete: :cascade
  add_foreign_key "workout_routine_day_exercises", "workout_routine_days"
  add_foreign_key "workout_routine_days", "workout_routines"
  add_foreign_key "workout_routines", "users"
  add_foreign_key "workout_sets", "exercises", on_delete: :restrict
  add_foreign_key "workout_sets", "supersets", on_delete: :nullify
  add_foreign_key "workout_sets", "workouts"
  add_foreign_key "workouts", "users"
  add_foreign_key "workouts", "workout_imports", on_delete: :nullify
  add_foreign_key "workouts", "workout_routine_days", on_delete: :nullify
end
