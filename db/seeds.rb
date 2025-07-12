user = User.create!(email_address: 'user@example.com', password: 'password', password_confirmation: 'password')

workout_day = WorkoutRoutine.create!(
  name: 'Workout Day',
  user:,
)

# create exercises
[
  { name: 'Bench Press', muscles: 'Chest', with_band: false, with_weights: true },
  { name: 'Squat', muscles: 'Legs', with_band: false, with_weights: true },
  { name: 'Deadlift', muscles: 'Back', with_band: false, with_weights: true },
  { name: 'Overhead Press', muscles: 'Shoulders', with_band: false, with_weights: true },
  { name: 'Pull-up', muscles: 'Back', with_band: true, with_weights: false },
  { name: 'Push-up', muscles: 'Chest', with_band: true, with_weights: false },
].each do |exercise_data|
  Exercise.create!(exercise_data)
end

day = workout_day.workout_routine_days.create!(
  name: 'Day 1',
)
day.exercises << Exercise.all
