user = User.create!(email_address: 'user@example.com', password: 'password', password_confirmation: 'password')

workout_day = WorkoutRoutine.create!(
  name: 'Workout Day',
  user:,
)

# Seed muscles first
MusclesSeeder.new.call

# create exercises
[
  { name: 'Bench Press', muscle: Muscle.find_by(name: 'chest'), with_band: false, with_weights: true },
  { name: 'Squat', muscle: Muscle.find_by(name: 'legs'), with_band: false, with_weights: true },
  { name: 'Deadlift', muscle: Muscle.find_by(name: 'back'), with_band: false, with_weights: true },
  { name: 'Overhead Press', muscle: Muscle.find_by(name: 'shoulders'), with_band: false, with_weights: true },
  { name: 'Pull-up', muscle: Muscle.find_by(name: 'back'), with_band: true, with_weights: false },
  { name: 'Push-up', muscle: Muscle.find_by(name: 'chest'), with_band: true, with_weights: false },
].each do |exercise_data|
  Exercise.create!(exercise_data)
end

day = workout_day.workout_routine_days.create!(
  name: 'Day 1',
)
day.exercises << Exercise.all
day_2 = workout_day.workout_routine_days.create!(
  name: 'Day 2',
)
day_2.exercises << Exercise.all

50.times do |i|
  next unless i.odd?
  workout = Workout.create!(
    user:,
    workout_routine_day: rand(0..1).zero? ? day : day_2,
    started_at: Time.current - i.days,
    ended_at: Time.current - i.days + rand(30..90).minutes,
  )

  day.exercises.each do |exercise|
    workout_set = workout.workout_sets.create!(
      exercise:,
      started_at: workout.started_at + rand(0..15).minutes,
      ended_at: workout.started_at + rand(16..30).minutes,
    )

    rand(3..5).times do
      workout_set.workout_reps.create!(
        reps: rand(5..12),
        weight: exercise.with_weights ? rand(5..25) : 0,
      )
    end
  end
end
