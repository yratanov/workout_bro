# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id              :integer          not null, primary key
#  ai_api_key      :string
#  ai_model        :string
#  ai_provider     :string
#  email_address   :string           not null
#  first_name      :string
#  last_name       :string
#  locale          :string           default("en")
#  password_digest :string           not null
#  role            :integer          default("user"), not null
#  setup_completed :boolean          default(FALSE), not null
#  weight_max      :float            default(100.0), not null
#  weight_min      :float            default(2.5), not null
#  weight_step     :float            default(2.5), not null
#  weight_unit     :string           default("kg"), not null
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
  encrypts :ai_api_key

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
  has_many :personal_records, dependent: :destroy
  has_many :supersets, dependent: :destroy
  has_many :push_subscriptions, dependent: :destroy
  has_many :scheduled_push_notifications, dependent: :destroy
  has_one :ai_trainer, dependent: :destroy

  AVAILABLE_LOCALES = %w[en ru].freeze
  WEIGHT_UNITS = %w[kg lbs].freeze

  validates :email_address, presence: true, uniqueness: true
  validates :password_digest, presence: true
  validates :locale, inclusion: { in: AVAILABLE_LOCALES }, allow_nil: true
  validates :weight_unit, inclusion: { in: WEIGHT_UNITS }
  validates :weight_min, numericality: { greater_than: 0 }
  validates :weight_max, numericality: { greater_than: :weight_min }
  validates :weight_step, numericality: { greater_than: 0 }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def setup_completed?
    setup_completed
  end

  def ai_configured?
    ai_provider.present? && ai_model.present? && ai_api_key.present?
  end

  def garmin_credential
    third_party_credentials.find_or_initialize_by(provider: "garmin")
  end
end
