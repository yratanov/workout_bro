# == Schema Information
#
# Table name: invites
# Database name: primary
#
#  id              :integer          not null, primary key
#  token           :string           not null
#  used_at         :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  used_by_user_id :integer
#  user_id         :integer          not null
#
# Indexes
#
#  index_invites_on_token            (token) UNIQUE
#  index_invites_on_used_by_user_id  (used_by_user_id)
#  index_invites_on_user_id          (user_id)
#
# Foreign Keys
#
#  used_by_user_id  (used_by_user_id => users.id)
#  user_id          (user_id => users.id)
#
require 'rails_helper'

describe Invite do
  pending "add some examples to (or delete) #{__FILE__}"
end
