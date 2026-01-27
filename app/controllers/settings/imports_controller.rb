# frozen_string_literal: true

module Settings
  class ImportsController < ApplicationController
    def show
      @workout_imports = current_user.workout_imports.order(created_at: :desc).limit(10)
      @workout_import = current_user.workout_imports.new
    end

    def create
      @workout_import = current_user.workout_imports.new(import_params)
      @workout_import.original_filename ||= params.dig(:workout_import, :file)&.original_filename

      if @workout_import.save
        WorkoutImportJob.perform_later(workout_import: @workout_import)
        redirect_to settings_imports_path, notice: I18n.t("controllers.settings.imports.started")
      else
        @workout_imports = current_user.workout_imports.order(created_at: :desc).limit(10)
        render :show, status: :unprocessable_entity
      end
    end

    def status
      @workout_import = current_user.workout_imports.find(params[:id])

      render json: {
        status: @workout_import.status,
        imported_count: @workout_import.imported_count,
        skipped_count: @workout_import.skipped_count,
        error_details: @workout_import.error_details
      }
    end

    def destroy
      @workout_import = current_user.workout_imports.find(params[:id])
      deleted_count = @workout_import.workouts.destroy_all.count
      @workout_import.destroy!

      redirect_to settings_imports_path,
        notice: I18n.t("controllers.settings.imports.reverted", count: deleted_count)
    end

    private

    def import_params
      params.require(:workout_import).permit(:file, :original_filename)
    end
  end
end
