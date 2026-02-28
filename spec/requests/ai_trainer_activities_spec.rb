describe "AiTrainerActivities" do
  fixtures :all

  let(:user) { users(:john) }

  describe "GET /ai" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns success" do
        get ai_trainer_activities_path
        expect(response).to have_http_status(:success)
      end

      it "shows completed activities" do
        get ai_trainer_activities_path
        expect(response.body).to include("Workout Feedback")
        expect(response.body).to include("Weekly Report")
      end

      it "does not show pending activities" do
        get ai_trainer_activities_path
        # pending activity has no content so won't appear
        expect(response.body).to include("Training Review")
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get ai_trainer_activities_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /ai/:id" do
    context "when authenticated" do
      before { sign_in(user) }

      it "shows the activity" do
        activity = ai_trainer_activities(:johns_workout_review)
        get ai_trainer_activity_path(activity)
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Good volume progression")
      end

      it "marks the activity as viewed" do
        activity = ai_trainer_activities(:johns_workout_review)
        expect(activity.viewed_at).to be_nil

        get ai_trainer_activity_path(activity)

        activity.reload
        expect(activity.viewed_at).to be_present
      end

      it "does not update viewed_at if already viewed" do
        activity = ai_trainer_activities(:johns_full_review)
        original_time = activity.viewed_at

        get ai_trainer_activity_path(activity)

        activity.reload
        expect(activity.viewed_at).to be_within(1.second).of(original_time)
      end

      it "shows workout link for workout_review activities" do
        activity = ai_trainer_activities(:johns_workout_review)
        get ai_trainer_activity_path(activity)
        expect(response.body).to include("View Workout")
      end

      it "shows week range for weekly_report activities" do
        activity = ai_trainer_activities(:johns_weekly_report)
        get ai_trainer_activity_path(activity)
        expect(response).to have_http_status(:success)
      end
    end
  end
end
