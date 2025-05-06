class SeedExercises < ActiveRecord::Migration[8.0]
  def change
    [
      ["Bent Over Dumbbell Row", "Back"],
      ["Dumbbell Bench Press", "Chest"],
      ["Dumbbell Lateral Raise", "Shoulders"],
      ["Dumbbell Pullover", "Chest"],
      ["Dumbbell Bicep Curl", "Biceps"],
      ["Dumbbell Tricep Extension", "Triceps"],
      ["Dumbbell Shrug", "Traps"],

      ["Goblet Squat", "Quads"],
      ["Dumbbell Stiff Leg Deadlift", "Hamstrings"],
      ["Dumbbell Plie Squat", "Glutes"],
      ["Dumbbell Hamstring Curl", "Hamstrings"],
      ["Standing Dumbbell Calf Raise", "Calves"],
      ["Plank", "Core"],

      ["One Arm Dumbbell Row", "Back"],
      ["Dumbbell Shoulder Press", "Shoulders"],
      ["Incline Dumbbell Bench Press", "Chest"],
      ["Chest Supported Dumbbell Row", "Back"],
      ["Dumbbell Hammer Curl", "Biceps"],
      ["Dumbbell Floor Press", "Chest"],
      ["Seated Dumbbell Shrug", "Traps"],

      ["Dumbbell Rear Lunge", "Quads"],
      ["Dumbbell Hip Thrust", "Glutes"],
      ["Dumbbell Split Squat", "Quads"],
      ["Seated Dumbbell Calf Raise", "Calves"],
      ["Planks", "Core"],
      ["Dumbbell Squat", "Quads"],
      ["Lying Dumbbell Extension", "Triceps"],
    ].each do |name, muscles|
      Exercise.find_or_create_by(name: name, muscles: muscles)
    end
  end
end
