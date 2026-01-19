# == Schema Information
#
# Table name: muscles
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_muscles_on_name  (name) UNIQUE
#
class Muscle < ApplicationRecord
  has_many :exercises, dependent: :nullify

  validates :name, presence: true, uniqueness: true

  def human_name
    I18n.t("muscles.#{name}", default: name.titleize)
  end
end
