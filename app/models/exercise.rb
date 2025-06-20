# == Schema Information
#
# Table name: exercises
#
#  id           :integer          not null, primary key
#  muscles      :string
#  name         :string
#  with_band    :boolean          default(FALSE), not null
#  with_weights :boolean          default(TRUE), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class Exercise < ApplicationRecord
end
