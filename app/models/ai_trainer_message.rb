# frozen_string_literal: true

# == Schema Information
#
# Table name: ai_trainer_messages
# Database name: primary
#
#  id                     :integer          not null, primary key
#  content                :text             not null
#  role                   :integer          not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  ai_trainer_activity_id :integer          not null
#
# Indexes
#
#  index_ai_trainer_messages_on_ai_trainer_activity_id  (ai_trainer_activity_id)
#
# Foreign Keys
#
#  ai_trainer_activity_id  (ai_trainer_activity_id => ai_trainer_activities.id)
#
class AiTrainerMessage < ApplicationRecord
  belongs_to :ai_trainer_activity

  enum :role, { user: 0, assistant: 1 }

  validates :role, presence: true
  validates :content, presence: true
end
