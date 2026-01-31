class PersonalRecordsController < ApplicationController
  def index
    @personal_records =
      current_user.personal_records.timeline.group_by(&:achieved_on)
  end
end
