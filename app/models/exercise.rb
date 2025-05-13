# == Schema Information
#
# Table name: exercises
#
#  id         :integer          not null, primary key
#  name       :string
#  muscles    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Exercise < ApplicationRecord
end
