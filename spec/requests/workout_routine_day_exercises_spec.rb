describe "WorkoutRoutineDayExercises" do
  fixtures :users,
           :workout_routines,
           :workout_routine_days,
           :workout_routine_day_exercises,
           :exercises

  let(:user) { users(:john) }
  let(:workout_routine) { workout_routines(:push_pull_legs) }
  let(:workout_routine_day) { workout_routine_days(:push_day) }
  let(:exercise) { exercises(:squat) }
  let(:workout_routine_day_exercise) do
    workout_routine_day_exercises(:push_day_bench)
  end

  before { sign_in(user) }

  describe "GET new" do
    it "returns success" do
      get new_workout_routine_workout_routine_day_workout_routine_day_exercise_path(
            workout_routine,
            workout_routine_day
          )
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST create" do
    context "with valid params" do
      it "creates a new workout routine day exercise" do
        expect {
          post workout_routine_workout_routine_day_workout_routine_day_exercises_path(
                 workout_routine,
                 workout_routine_day
               ),
               params: {
                 workout_routine_day_exercise: {
                   exercise_id: exercise.id,
                   workout_routine_day_id: workout_routine_day.id
                 }
               },
               as: :turbo_stream
        }.to change(WorkoutRoutineDayExercise, :count).by(1)
      end

      it "sets position automatically" do
        post workout_routine_workout_routine_day_workout_routine_day_exercises_path(
               workout_routine,
               workout_routine_day
             ),
             params: {
               workout_routine_day_exercise: {
                 exercise_id: exercise.id,
                 workout_routine_day_id: workout_routine_day.id
               }
             },
             as: :turbo_stream
        expect(WorkoutRoutineDayExercise.last.position).to eq(2)
      end
    end

    context "with invalid params" do
      it "renders new form" do
        post workout_routine_workout_routine_day_workout_routine_day_exercises_path(
               workout_routine,
               workout_routine_day
             ),
             params: {
               workout_routine_day_exercise: {
                 exercise_id: nil,
                 workout_routine_day_id: workout_routine_day.id
               }
             },
             as: :turbo_stream
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the workout routine day exercise" do
      expect {
        delete workout_routine_workout_routine_day_workout_routine_day_exercise_path(
                 workout_routine,
                 workout_routine_day,
                 workout_routine_day_exercise
               ),
               as: :turbo_stream
      }.to change(WorkoutRoutineDayExercise, :count).by(-1)
    end
  end

  describe "PATCH move" do
    let(:second_exercise) do
      WorkoutRoutineDayExercise.create!(
        workout_routine_day: workout_routine_day,
        exercise: exercise,
        position: 2
      )
    end

    before do
      workout_routine_day_exercise.update!(position: 1)
      second_exercise
    end

    it "moves the exercise to a new position" do
      patch move_workout_routine_workout_routine_day_workout_routine_day_exercise_path(
              workout_routine,
              workout_routine_day,
              workout_routine_day_exercise
            ),
            params: {
              position: 2
            }

      expect(response).to have_http_status(:ok)
      expect(workout_routine_day_exercise.reload.position).to eq(2)
    end
  end
end
