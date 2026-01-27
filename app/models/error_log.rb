# frozen_string_literal: true

# == Schema Information
#
# Table name: error_logs
# Database name: primary
#
#  id          :integer          not null, primary key
#  backtrace   :json
#  context     :json
#  error_class :string           not null
#  message     :text
#  severity    :integer          default("error"), not null
#  source      :string           default("application")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  request_id  :string
#
# Indexes
#
#  index_error_logs_on_created_at  (created_at)
#  index_error_logs_on_severity    (severity)
#
class ErrorLog < ApplicationRecord
  enum :severity, { error: 0, warning: 1, info: 2 }

  validates :error_class, presence: true
  validates :severity, presence: true

  scope :recent, -> { order(created_at: :desc) }
end
