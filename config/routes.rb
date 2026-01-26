Rails.application.routes.draw do
  resource :setup, only: %i[show update], controller: "setup"
  resource :session
  resources :passwords, param: :token
  resources :workouts, only: %i[index show new create edit update destroy] do
    member do
      get :modal
      post :stop
      post :pause
      post :resume
    end
  end

  resources :exercises
  resources :workout_sets, only: %i[new create show edit update destroy] do
    member do
      post :stop
      post :reopen
    end
  end

  resources :workout_reps, only: %i[new create show edit update destroy]
  resources :workout_routines, only: %i[index new create show edit update destroy] do
    resources :workout_routine_days, only: %i[index new create show edit update destroy] do
      resources :workout_routine_day_exercises, only: %i[destroy new create] do
        member do
          patch :move
        end
      end
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "workouts#index"
  get "stats", to: "stats#index", as: :stats

  namespace :settings do
    get "/", to: redirect("/settings/profile")
    resource :profile, only: %i[show update], controller: "profile"
    resource :garmin, only: %i[show update], controller: "garmin" do
      post :sync
    end
    resource :logs, only: %i[show], controller: "logs"
    resource :invites, only: %i[show create], controller: "invites" do
      delete ":id", action: :destroy, as: :invite, on: :collection
    end
  end

  get "use-invite/:token", to: "invites#show", as: :use_invite
  post "use-invite/:token", to: "invites#create"
end
