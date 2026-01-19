# == Schema Information
#
# Table name: users
#
#  id              :integer          not null, primary key
#  email_address   :string           not null
#  password_digest :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_users_on_email_address  (email_address) UNIQUE
#

class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :workouts, dependent: :destroy
  has_many :workout_sets, through: :workouts
  has_many :workout_reps, through: :workout_sets
  has_many :workout_routines, dependent: :destroy
  has_many :third_party_credentials, dependent: :destroy
  has_many :sync_logs, dependent: :destroy

  validates :email_address, presence: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def garmin_credential
    third_party_credentials.find_or_initialize_by(provider: "garmin")
  end
end
