class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  rescue_from StandardError, with: :log_and_reraise_error

  private

  def log_and_reraise_error(error)
    ErrorLogger.log(
      error,
      source: "job",
      context: {
        job_class: self.class.name,
        job_id: job_id,
        queue_name: queue_name,
        arguments: arguments
      }
    )
    raise error
  end
end
