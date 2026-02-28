# frozen_string_literal: true

# == Schema Information
#
# Table name: ai_logs
# Database name: primary
#
#  id          :integer          not null, primary key
#  action      :string           not null
#  duration_ms :integer
#  error       :text
#  model       :string
#  prompt      :text
#  response    :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  user_id     :integer          not null
#
# Indexes
#
#  index_ai_logs_on_created_at  (created_at)
#  index_ai_logs_on_user_id     (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
class AiLog < ApplicationRecord
  belongs_to :user

  scope :recent, -> { order(created_at: :desc) }
end
