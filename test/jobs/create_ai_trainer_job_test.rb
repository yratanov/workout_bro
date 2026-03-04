require "test_helper"

class CreateAiTrainerJobTest < ActiveJob::TestCase
  setup do
    @user = users(:john)
    @user.update!(
      ai_provider: "gemini",
      ai_model: "gemini-2.0-flash",
      ai_api_key: "test-key"
    )
    @ai_trainer = @user.ai_trainer
    @ai_trainer.update!(status: :pending, trainer_profile: nil)
  end

  test "generates trainer profile and marks as completed" do
    VCR.use_cassette("jobs/create_trainer/success") do
      CreateAiTrainerJob.new.perform(ai_trainer: @ai_trainer)
    end

    @ai_trainer.reload
    assert @ai_trainer.completed?
    assert_equal "Generated profile text", @ai_trainer.trainer_profile
    assert_nil @ai_trainer.error_details
  end

  test "sets status to in_progress at the start" do
    statuses = []
    @ai_trainer.define_singleton_method(:in_progress!) do
      statuses << :in_progress
      super()
    end

    VCR.use_cassette("jobs/create_trainer/success") do
      CreateAiTrainerJob.new.perform(ai_trainer: @ai_trainer)
    end

    assert_includes statuses, :in_progress
  end

  test "enqueues GenerateFullReviewJob when train_on_existing_data is true" do
    @ai_trainer.update!(train_on_existing_data: true)

    assert_enqueued_with(job: GenerateFullReviewJob) do
      VCR.use_cassette("jobs/create_trainer/success") do
        CreateAiTrainerJob.new.perform(ai_trainer: @ai_trainer)
      end
    end
  end

  test "does not enqueue GenerateFullReviewJob when train_on_existing_data is false" do
    @ai_trainer.update!(train_on_existing_data: false)

    VCR.use_cassette("jobs/create_trainer/success") do
      CreateAiTrainerJob.new.perform(ai_trainer: @ai_trainer)
    end

    assert_enqueued_jobs 0, only: GenerateFullReviewJob
  end

  test "sets failed status on error and re-raises" do
    VCR.use_cassette("jobs/create_trainer/error") do
      assert_raises(StandardError) do
        CreateAiTrainerJob.new.perform(ai_trainer: @ai_trainer)
      end
    end

    @ai_trainer.reload
    assert @ai_trainer.failed?
    assert_not_nil @ai_trainer.error_details["message"]
  end
end
