require 'rails_helper'

describe GarminSyncService do
  fixtures :users

  let(:user) { users(:john) }
  let(:username) { 'test@example.com' }
  let(:password) { 'secret123' }
  let(:service) { described_class.new(user: user) }

  before do
    user.garmin_credential.update!(username: username, password: password)
  end

  describe '#call' do
    context 'when credentials are missing' do
      before do
        user.garmin_credential.update!(username: nil, encrypted_password: nil)
      end

      it 'raises MissingCredentialsError' do
        expect { service.call }.to raise_error(
          GarminSyncService::MissingCredentialsError,
          'Garmin credentials not configured'
        )
      end
    end

    context 'when Python script returns activities' do
      let(:activities_json) do
        {
          activities: [
            {
              started_at: '2024-01-15T08:30:00',
              distance_meters: 5000,
              duration_seconds: 1800
            },
            {
              started_at: '2024-01-16T07:00:00',
              distance_meters: 10000,
              duration_seconds: 3600
            }
          ]
        }.to_json
      end

      before do
        allow(Open3).to receive(:capture2).and_return(
          [ activities_json, instance_double(Process::Status, success?: true, exitstatus: 0) ]
        )
      end

      it 'creates run workouts for each activity' do
        expect { service.call }.to change(Workout, :count).by(2)
      end

      it 'returns import statistics' do
        result = service.call
        expect(result).to eq(imported: 2, skipped: 0)
      end

      it 'creates workouts with correct attributes' do
        service.call

        workout = Workout.find_by(started_at: Time.zone.parse('2024-01-15T08:30:00'))
        expect(workout).to have_attributes(
          user: user,
          workout_type: 'run',
          distance: 5000,
          time_in_seconds: 1800
        )
        expect(workout.ended_at).to eq(workout.started_at + 1800.seconds)
      end

      it 'calls Python script with credentials from database' do
        service.call

        expect(Open3).to have_received(:capture2).with(
          'python3',
          GarminSyncService::PYTHON_SCRIPT_PATH,
          username,
          password,
          '7'
        )
      end
    end

    context 'when activity already exists' do
      let(:existing_started_at) { Time.zone.parse('2024-01-15T08:30:00') }
      let(:activities_json) do
        {
          activities: [
            {
              started_at: '2024-01-15T08:30:00',
              distance_meters: 5000,
              duration_seconds: 1800
            }
          ]
        }.to_json
      end

      before do
        allow(Open3).to receive(:capture2).and_return(
          [ activities_json, instance_double(Process::Status, success?: true, exitstatus: 0) ]
        )

        Workout.create!(
          user: user,
          workout_type: :run,
          date: existing_started_at.to_date,
          started_at: existing_started_at,
          ended_at: existing_started_at + 30.minutes,
          distance: 5000,
          time_in_seconds: 1800
        )
      end

      it 'skips existing activities' do
        expect { service.call }.not_to change(Workout, :count)
      end

      it 'returns correct statistics' do
        result = service.call
        expect(result).to eq(imported: 0, skipped: 1)
      end
    end

    context 'when Python script fails' do
      before do
        allow(Open3).to receive(:capture2).and_return(
          [ '', instance_double(Process::Status, success?: false, exitstatus: 1) ]
        )
      end

      it 'raises an error' do
        expect { service.call }.to raise_error(GarminSyncService::Error, /Python script failed/)
      end
    end

    context 'when Python script returns an error' do
      let(:error_json) { { error: 'Invalid credentials' }.to_json }

      before do
        allow(Open3).to receive(:capture2).and_return(
          [ error_json, instance_double(Process::Status, success?: true, exitstatus: 0) ]
        )
      end

      it 'raises an error with the message' do
        expect { service.call }.to raise_error(GarminSyncService::Error, 'Invalid credentials')
      end
    end

    context 'when Python script returns empty activities' do
      let(:empty_json) { { activities: [] }.to_json }

      before do
        allow(Open3).to receive(:capture2).and_return(
          [ empty_json, instance_double(Process::Status, success?: true, exitstatus: 0) ]
        )
      end

      it 'returns zero imports' do
        result = service.call
        expect(result).to eq(imported: 0, skipped: 0)
      end
    end
  end

  describe 'with custom days parameter' do
    let(:service) { described_class.new(user: user, days: 14) }
    let(:activities_json) { { activities: [] }.to_json }

    before do
      allow(Open3).to receive(:capture2).and_return(
        [ activities_json, instance_double(Process::Status, success?: true, exitstatus: 0) ]
      )
    end

    it 'passes days to Python script' do
      service.call

      expect(Open3).to have_received(:capture2).with(
        'python3',
        GarminSyncService::PYTHON_SCRIPT_PATH,
        username,
        password,
        '14'
      )
    end
  end
end
