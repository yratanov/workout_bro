require "test_helper"

class ApplicationJobTest < ActiveJob::TestCase
  class FailingTestJob < ApplicationJob
    self.queue_adapter = :inline

    def perform
      raise StandardError, "something went wrong"
    end
  end

  test "calls ErrorLogger.log when a job raises an error" do
    ErrorLogger
      .expects(:log)
      .with do |error, **opts|
        error.is_a?(StandardError) && error.message == "something went wrong" &&
          opts[:source] == "job" &&
          opts[:context][:job_class] == "ApplicationJobTest::FailingTestJob"
      end
      .once

    assert_raises(StandardError, "something went wrong") do
      FailingTestJob.perform_now
    end
  end

  test "re-raises the error after logging" do
    ErrorLogger.stubs(:log)

    error = assert_raises(StandardError) { FailingTestJob.perform_now }

    assert_equal "something went wrong", error.message
  end

  test "includes job_id and queue_name in error context" do
    captured_context = nil
    ErrorLogger
      .stubs(:log)
      .with do |_error, **opts|
        captured_context = opts[:context]
        true
      end

    assert_raises(StandardError) { FailingTestJob.perform_now }

    assert_equal "ApplicationJobTest::FailingTestJob",
                 captured_context[:job_class]
    assert captured_context[:job_id].present?
    assert captured_context[:queue_name].present?
  end
end
