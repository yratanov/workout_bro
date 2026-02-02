# frozen_string_literal: true

module Settings
  class ExportsController < ApplicationController
    def show
      @completed_workouts_count =
        current_user.workouts.where.not(ended_at: nil).count
      @exercises_count = current_user.exercises.count
    end

    def create
      csv_data = WorkoutExporter.new(user: current_user).call
      filename = "workout_bro_export_#{Date.current.iso8601}.csv"

      send_data csv_data,
                filename: filename,
                type: "text/csv",
                disposition: "attachment"
    end
  end
end
