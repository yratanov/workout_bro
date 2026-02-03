# == Schema Information
#
# Table name: push_subscriptions
# Database name: primary
#
#  id           :integer          not null, primary key
#  auth         :string           not null
#  endpoint     :string           not null
#  last_used_at :datetime
#  p256dh       :string           not null
#  user_agent   :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer          not null
#
# Indexes
#
#  index_push_subscriptions_on_user_id               (user_id)
#  index_push_subscriptions_on_user_id_and_endpoint  (user_id,endpoint) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class PushSubscription < ApplicationRecord
  belongs_to :user

  validates :endpoint, presence: true, uniqueness: { scope: :user_id }
  validates :p256dh, presence: true
  validates :auth, presence: true

  def touch_last_used
    update_column(:last_used_at, Time.current)
  end
end
