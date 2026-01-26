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
#  user_id      :integer          not null
#
# Indexes
#
#  index_exercises_on_muscle_id  (muscle_id)
#  index_exercises_on_user_id    (user_id)
#
# Foreign Keys
#
#  muscle_id  (muscle_id => muscles.id)
#  user_id    (user_id => users.id)
#

class Exercise < ApplicationRecord
  belongs_to :muscle, optional: true
  belongs_to :user

  has_many :workout_routine_day_exercises, dependent: :destroy
end
