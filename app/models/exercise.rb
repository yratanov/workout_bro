# == Schema Information
#
# Table name: exercises
#
#  id           :integer          not null, primary key
#  name         :string
#  with_band    :boolean          default(FALSE), not null
#  with_weights :boolean          default(TRUE), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  muscle_id    :integer
#
# Indexes
#
#  index_exercises_on_muscle_id  (muscle_id)
#
# Foreign Keys
#
#  muscle_id  (muscle_id => muscles.id)
#

class Exercise < ApplicationRecord
  belongs_to :muscle, optional: true

  has_many :workout_routine_day_exercises, dependent: :destroy
end
