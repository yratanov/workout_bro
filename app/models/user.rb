# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id              :integer          not null, primary key
#  email_address   :string           not null
#  first_name      :string
#  last_name       :string
#  locale          :string           default("en")
#  password_digest :string           not null
#  role            :integer          default("user"), not null
#  setup_completed :boolean          default(FALSE)
#  wizard_step     :integer          default(0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#

class User < ApplicationRecord
  has_secure_password

  enum :role, { user: 0, admin: 1 }

  has_many :sessions, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :workout_sets, through: :workouts
  has_many :workout_reps, through: :workout_sets
  has_many :workout_routines, dependent: :destroy
  has_many :exercises, dependent: :destroy
  has_many :third_party_credentials, dependent: :destroy
  has_many :sync_logs, dependent: :destroy
  has_many :invites, dependent: :destroy
  has_many :used_invites,
           class_name: "Invite",
           foreign_key: :used_by_user_id,
           dependent: :nullify,
           inverse_of: :used_by_user
  has_many :workout_imports, dependent: :destroy

  AVAILABLE_LOCALES = %w[en ru].freeze

  validates :email_address, presence: true, uniqueness: true
  validates :locale, inclusion: { in: AVAILABLE_LOCALES }, allow_nil: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def setup_completed?
    setup_completed
  end

  def garmin_credential
    third_party_credentials.find_or_initialize_by(provider: "garmin")
  end
end
