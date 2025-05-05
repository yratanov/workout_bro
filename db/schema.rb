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

ActiveRecord::Schema[8.0].define(version: 2025_05_05_064753) do
  create_table "exercises", force: :cascade do |t|
    t.string "name"
    t.string "muscles"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "workout_reps", force: :cascade do |t|
    t.float "weight"
    t.integer "reps"
    t.integer "workout_set_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workout_set_id"], name: "index_workout_reps_on_workout_set_id"
  end

  create_table "workout_sets", force: :cascade do |t|
    t.datetime "started_at"
    t.datetime "ended_at"
    t.integer "workout_id", null: false
    t.integer "exercise_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["exercise_id"], name: "index_workout_sets_on_exercise_id"
    t.index ["workout_id"], name: "index_workout_sets_on_workout_id"
  end

  create_table "workouts", force: :cascade do |t|
    t.date "date"
    t.datetime "started_at"
    t.datetime "ended_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "workout_reps", "workout_sets"
  add_foreign_key "workout_sets", "exercises"
  add_foreign_key "workout_sets", "workouts"
end
