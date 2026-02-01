# == Schema Information
#
# Table name: superset_exercises
# Database name: primary
#
#  id          :integer          not null, primary key
#  position    :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  exercise_id :integer          not null
#  superset_id :integer          not null
#
# Indexes
#
#  index_superset_exercises_on_exercise_id               (exercise_id)
#  index_superset_exercises_on_superset_id               (superset_id)
#  index_superset_exercises_on_superset_id_and_position  (superset_id,position)
#
# Foreign Keys
#
#  exercise_id  (exercise_id => exercises.id)
#  superset_id  (superset_id => supersets.id) ON DELETE => cascade
#
class SupersetExercise < ApplicationRecord
  belongs_to :superset
  belongs_to :exercise

  validates :position, presence: true, numericality: { greater_than: 0 }
  validates :exercise_id, uniqueness: { scope: :superset_id }
end
