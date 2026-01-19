# == Schema Information
#
# Table name: third_party_credentials
#
#  id                 :integer          not null, primary key
#  encrypted_password :string
#  provider           :string           not null
#  username           :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  user_id            :integer          not null
#
# Indexes
#
#  index_third_party_credentials_on_user_id               (user_id)
#  index_third_party_credentials_on_user_id_and_provider  (user_id,provider) UNIQUE
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#

class ThirdPartyCredential < ApplicationRecord
  PROVIDERS = %w[garmin].freeze

  belongs_to :user

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :provider, uniqueness: { scope: :user_id }

  encrypts :encrypted_password

  def password=(value)
    self.encrypted_password = value if value.present?
  end

  def password
    nil
  end
end
