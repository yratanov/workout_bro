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
require 'rails_helper'

RSpec.describe Muscle, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
