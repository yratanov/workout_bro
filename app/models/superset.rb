# == Schema Information
#
# Table name: supersets
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_supersets_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class Superset < ApplicationRecord
  belongs_to :user

  has_many :superset_exercises, -> { order(:position) }, dependent: :destroy
  has_many :exercises, through: :superset_exercises
  has_many :workout_routine_day_exercises, dependent: :destroy
  has_many :workout_sets, dependent: :nullify

  validates :name, presence: true

  def display_name
    name
  end
end
