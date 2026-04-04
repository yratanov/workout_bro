# == Schema Information
#
# Table name: third_party_credentials
# Database name: primary
#
#  id                 :integer          not null, primary key
#  access_token       :string
#  encrypted_password :string
#  provider           :string           not null
#  refresh_token      :string
#  token_expires_at   :datetime
#  username           :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :integer          not null
#
# Indexes
#
#  index_third_party_credentials_on_user_id_and_provider  (user_id,provider) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

class ThirdPartyCredential < ApplicationRecord
  PROVIDERS = %w[garmin strava].freeze

  belongs_to :user

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :provider, uniqueness: { scope: :user_id }

  encrypts :encrypted_password
  encrypts :access_token
  encrypts :refresh_token

  scope :for_provider, ->(provider) { where(provider: provider) }

  def password=(value)
    self.encrypted_password = value if value.present?
  end

  def password
    nil
  end

  def oauth_configured?
    access_token.present? && refresh_token.present?
  end

  def token_expired?
    return true if token_expires_at.blank?

    token_expires_at < 5.minutes.from_now
  end
end
