# == Schema Information
#
# Table name: invites
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
class Invite < ApplicationRecord
  belongs_to :user
  belongs_to :used_by_user, class_name: "User", optional: true

  validates :token, presence: true, uniqueness: true

  before_validation :generate_token, on: :create

  def used?
    used_at.present?
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(16)
  end
end
