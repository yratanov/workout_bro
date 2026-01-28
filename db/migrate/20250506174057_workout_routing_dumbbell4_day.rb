class WorkoutRoutingDumbbell4Day < ActiveRecord::Migration[8.0]
  def change
    return unless ENV["SEED_DEFAULT_DATA"] == "true"

    routine = WorkoutRoutine.create(name: "Dumbbell 4 Day")
    day1 =
      WorkoutRoutineDay.create(
        name: "Day 1: Upper body",
        workout_routine: routine
      )
    [
      "Bent Over Dumbbell Row",
      "Dumbbell Bench Press",
      "Dumbbell Lateral Raise",
      "Dumbbell Pullover",
      "Dumbbell Bicep Curl",
      "Dumbbell Tricep Extension",
      "Dumbbell Shrug"
    ].each do |exercise_name|
      day1.exercises << Exercise.find_by(name: exercise_name)
    end

    day2 =
      WorkoutRoutineDay.create(
        name: "Day 2: Lower body",
        workout_routine: routine
      )

    [
      "Goblet Squat",
      "Dumbbell Stiff Leg Deadlift",
      "Dumbbell Plie Squat",
      "Dumbbell Hamstring Curl",
      "Standing Dumbbell Calf Raise",
      "Floor Crunch"
    ].each do |exercise_name|
      day2.exercises << Exercise.find_by(name: exercise_name)
    end

    day3 =
      WorkoutRoutineDay.create(
        name: "Day 3: Upper body",
        workout_routine: routine
      )

    [
      "One Arm Dumbbell Row",
      "Dumbbell Shoulder Press",
      "Incline Dumbbell Bench Press",
      "Chest Supported Dumbbell Row",
      "Dumbbell Hammer Curl",
      "Dumbbell Floor Press",
      "Seated Dumbbell Shrug"
    ].each do |exercise_name|
      day3.exercises << Exercise.find_by(name: exercise_name)
    end

    day4 =
      WorkoutRoutineDay.create(
        name: "Day 4: Lower body",
        workout_routine: routine
      )

    [
      "Dumbbell Rear Lunge",
      "Dumbbell Hip Thrust",
      "Dumbbell Split Squat",
      "Seated Dumbbell Calf Raise",
      "Floor Crunch",
      "Dumbbell Squat",
      "Lying Dumbbell Extension"
    ].each do |exercise_name|
      day4.exercises << Exercise.find_by(name: exercise_name)
    end
  end
end
