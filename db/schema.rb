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

ActiveRecord::Schema[8.0].define(version: 2026_01_26_214856) do
  create_table "exercises", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "with_weights", default: true, null: false
    t.boolean "with_band", default: false, null: false
    t.integer "muscle_id"
    t.integer "user_id", null: false
    t.index ["muscle_id"], name: "index_exercises_on_muscle_id"
    t.index ["user_id"], name: "index_exercises_on_user_id"
  end

  create_table "muscles", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_muscles_on_name", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "sync_logs", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "log_type", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.text "message"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_sync_logs_on_created_at"
    t.index ["log_type"], name: "index_sync_logs_on_log_type"
    t.index ["status"], name: "index_sync_logs_on_status"
    t.index ["user_id"], name: "index_sync_logs_on_user_id"
  end

  create_table "third_party_credentials", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "provider", null: false
    t.string "username"
    t.string "encrypted_password"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "provider"], name: "index_third_party_credentials_on_user_id_and_provider", unique: true
    t.index ["user_id"], name: "index_third_party_credentials_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "locale", default: "en"
    t.integer "wizard_step", default: 0
    t.boolean "setup_completed", default: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "workout_reps", force: :cascade do |t|
    t.float "weight"
    t.integer "reps"
    t.integer "workout_set_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "band"
    t.index ["workout_set_id"], name: "index_workout_reps_on_workout_set_id"
  end

  create_table "workout_routine_day_exercises", force: :cascade do |t|
    t.integer "workout_routine_day_id", null: false
    t.integer "exercise_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "position"
    t.index ["exercise_id"], name: "index_workout_routine_day_exercises_on_exercise_id"
    t.index ["workout_routine_day_id"], name: "index_workout_routine_day_exercises_on_workout_routine_day_id"
  end

  create_table "workout_routine_days", force: :cascade do |t|
    t.string "name"
    t.integer "workout_routine_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workout_routine_id"], name: "index_workout_routine_days_on_workout_routine_id"
  end

  create_table "workout_routines", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["user_id"], name: "index_workout_routines_on_user_id"
  end

  create_table "workout_sets", force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "workout_id", null: false
    t.integer "exercise_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "paused_at"
    t.integer "total_paused_seconds", default: 0
    t.index ["exercise_id"], name: "index_workout_sets_on_exercise_id"
    t.index ["workout_id"], name: "index_workout_sets_on_workout_id"
  end

  create_table "workouts", force: :cascade do |t|
    t.date "date"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "workout_routine_day_id"
    t.integer "user_id"
    t.integer "workout_type", default: 0, null: false
    t.integer "distance"
    t.integer "time_in_seconds"
    t.datetime "paused_at"
    t.integer "total_paused_seconds", default: 0
    t.index ["user_id"], name: "index_workouts_on_user_id"
    t.index ["workout_routine_day_id"], name: "index_workouts_on_workout_routine_day_id"
  end

  add_foreign_key "exercises", "muscles"
  add_foreign_key "exercises", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "sync_logs", "users"
  add_foreign_key "third_party_credentials", "users"
  add_foreign_key "workout_reps", "workout_sets"
  add_foreign_key "workout_routine_day_exercises", "exercises"
  add_foreign_key "workout_routine_day_exercises", "workout_routine_days"
  add_foreign_key "workout_routine_days", "workout_routines"
  add_foreign_key "workout_routines", "users"
  add_foreign_key "workout_sets", "exercises"
  add_foreign_key "workout_sets", "workouts"
  add_foreign_key "workouts", "users"
  add_foreign_key "workouts", "workout_routine_days"
end
