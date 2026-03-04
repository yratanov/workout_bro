user =
  User.create!(
    email_address: "user@example.com",
    password: "password",
    password_confirmation: "password",
    setup_completed: true,
    wizard_step: 4
  )

workout_day = WorkoutRoutine.create!(name: "Workout Day", user:)

# Seed muscles first
MusclesSeeder.new.call

# create exercises
[
  {
    name: "Bench Press",
    muscle: Muscle.find_by(name: "chest"),
    with_band: false,
    with_weights: true
  },
  {
    name: "Squat",
    muscle: Muscle.find_by(name: "legs"),
    with_band: false,
    with_weights: true
  },
  {
    name: "Deadlift",
    muscle: Muscle.find_by(name: "back"),
    with_band: false,
    with_weights: true
  },
  {
    name: "Overhead Press",
    muscle: Muscle.find_by(name: "shoulders"),
    with_band: false,
    with_weights: true
  },
  {
    name: "Pull-up",
    muscle: Muscle.find_by(name: "back"),
    with_band: true,
    with_weights: false
  },
  {
    name: "Push-up",
    muscle: Muscle.find_by(name: "chest"),
    with_band: true,
    with_weights: false
  }
].each { |exercise_data| Exercise.create!(exercise_data.merge(user:)) }

workout_day = WorkoutRoutine.last
day = workout_day.workout_routine_days.create!(name: "Day 1")
day.exercises << Exercise.all
day_2 = workout_day.workout_routine_days.create!(name: "Day 2")
day_2.exercises << Exercise.all

50.times do |i|
  next unless i.odd?
  workout =
    Workout.create!(
      user:,
      workout_routine_day: rand(0..1).zero? ? day : day_2,
      started_at: Time.current - i.days,
      ended_at: Time.current - i.days + rand(30..90).minutes
    )

  day.exercises.each do |exercise|
    workout_set =
      workout.workout_sets.create!(
        exercise:,
        started_at: workout.started_at + rand(0..15).minutes,
        ended_at: workout.started_at + rand(16..30).minutes
      )

    rand(3..5).times do
      workout_set.workout_reps.create!(
        reps: rand(5..12),
        weight: exercise.with_weights ? rand(5..25) : 0
      )
    end
  end
end

Workout
  .where.not(ended_at: nil)
  .order(:started_at)
  .find_each { |workout| PersonalRecordDetector.new(workout: workout).call }

# AI Trainer
ai_trainer =
  AiTrainer.create!(
    user:,
    approach: :balanced,
    communication_style: :motivational,
    goal_general_fitness: true,
    goal_build_muscle: true,
    train_on_existing_data: true,
    status: :completed,
    trainer_profile:
      "You are a balanced, motivational fitness trainer. The user focuses on " \
        "general fitness and muscle building. They prefer compound movements and " \
        "train consistently 3-4 times per week."
  )

# AI Trainer Activities
last_workout = Workout.where.not(ended_at: nil).order(:started_at).last
if last_workout
  AiTrainerActivity.create!(
    user:,
    ai_trainer:,
    workout: last_workout,
    activity_type: :workout_review,
    status: :completed,
    content:
      "Solid session today! Your bench press volume is up compared to last week — " \
        "great progression. Squat depth looked consistent across all sets. Consider " \
        "adding a pause at the bottom of your deadlifts to build strength off the floor.",
    viewed_at: 1.hour.ago,
    created_at: 1.day.ago
  )
end

AiTrainerActivity.create!(
  user:,
  ai_trainer:,
  activity_type: :weekly_report,
  status: :completed,
  week_start: Date.current.beginning_of_week(:monday) - 7.days,
  content:
    "**Weekly Summary:** 3 workouts completed this week with good consistency. " \
      "Total volume increased 8% over the previous week. New PR on bench press (80kg x 5). " \
      "Recovery between sessions looks adequate. Keep pushing on the compound lifts.",
  viewed_at: 1.hour.ago,
  created_at: 3.days.ago
)

AiTrainerActivity.create!(
  user:,
  ai_trainer:,
  activity_type: :full_review,
  status: :completed,
  content:
    "## Training Review\n\n" \
      "Over the past several weeks, you've maintained excellent consistency with 3-4 sessions " \
      "per week. Your compound lifts (bench, squat, deadlift) show steady linear progression. " \
      "Upper body strength is developing well, with bench press progressing from 60kg to 80kg. " \
      "\n\n### Areas for Improvement\n" \
      "- Consider adding more posterior chain work (Romanian deadlifts, hip thrusts)\n" \
      "- Shoulder mobility could benefit from dedicated warm-up drills\n" \
      "- Rest periods between heavy sets could be slightly longer (3-4 min) for strength gains",
  viewed_at: 1.hour.ago,
  created_at: 1.week.ago
)

# AI Memories
[
  {
    category: :schedule,
    content: "Typically trains 3-4 times per week, preferring mornings"
  },
  { category: :schedule, content: "Tends to skip Friday workouts" },
  {
    category: :equipment,
    content: "Has access to a full gym with barbells, dumbbells, and cables"
  },
  { category: :health, content: "No reported injuries or limitations" },
  {
    category: :preferences,
    content: "Prefers compound movements over isolation exercises"
  },
  {
    category: :preferences,
    content: "Likes to superset opposing muscle groups"
  },
  {
    category: :progress,
    content: "Bench press has increased from 60kg to 80kg over 2 months"
  },
  {
    category: :progress,
    content: "Squat form has improved significantly since starting"
  },
  { category: :behavior, content: "Consistently logs all sets and reps" },
  { category: :goals, content: "Wants to bench press 100kg by end of year" },
  {
    category: :goals,
    content:
      "Interested in improving running endurance alongside strength training"
  }
].each { |memory_data| AiMemory.create!(memory_data.merge(user:, ai_trainer:)) }

puts "Seeded AI trainer, #{AiTrainerActivity.count} activities, and #{AiMemory.count} memories"
