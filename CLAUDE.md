# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Workout Bro is a Ruby on Rails 8.0.2 fitness tracking application for strength training and running workouts. It uses SQLite3 with the Solid stack (Cache, Queue, Cable) for zero external service dependencies.

## Development Commands

```bash
bin/setup              # Initial setup: install deps, prepare DB
bin/dev                # Start dev server with Foreman (web + CSS watch)
bin/rails server       # Start Rails server only
```

## Testing

Uses RSpec with Capybara for feature tests. Fixtures are stored in `test/fixtures/`.

```bash
bundle exec rspec                        # Run all tests
bundle exec rspec spec/features          # Run feature tests only
bundle exec rspec spec/requests          # Run request specs only
bundle exec rspec spec/features/workouts_spec.rb  # Run a single test file
```

**Test Structure:**
- `spec/features/` - Capybara feature tests (browser-based integration tests)
- `spec/requests/` - Controller/request specs
- `spec/support/` - Shared helpers (login_helpers.rb, capybara.rb)
- `test/fixtures/` - Test data fixtures (shared with RSpec)

## Code Quality

```bash
bin/rubocop            # Lint (Omakase Rails style)
bin/brakeman           # Security scan
bundle exec annotaterb # Add schema annotations to models
```

## Database

SQLite3 databases stored in `storage/`. Seeds create a test user (`user@example.com` / `password`) with sample workouts.

```bash
bin/rails db:seed      # Load sample data
bin/rails db:prepare   # Create + migrate + seed
```

## Architecture

**Domain Model:**
- User has many Workouts (strength or run type) and WorkoutRoutines
- WorkoutRoutine has many WorkoutRoutineDays, each with WorkoutRoutineDayExercises
- Workout has many WorkoutSets, each with WorkoutReps tracking weight/reps/band
- Exercises have muscles targeted and equipment flags (with_weights, with_band)

**Tech Stack:**
- Frontend: Hotwire (Turbo + Stimulus), Tailwind CSS v4, ViewComponent
- Auth: Session-based with bcrypt (no Devise)
- Assets: Propshaft with ImportMap
- Background: Solid Queue (no Redis)

**Key Routes:**
- `root` → workouts#index
- `POST /workouts/:id/stop` → end a workout
- `POST /workout_sets/:id/stop` → end a set
- `/stats` → statistics dashboard

## Deployment

Docker via Kamal. Requires `RAILS_MASTER_KEY` environment variable.

```bash
docker build -t workout_bro .
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<key> workout_bro
```

Alternative: `./deploy.sh` runs Ansible playbook.

## Internationalization (I18n)

**All user-facing strings must use I18n translations.** Never hardcode text in views or controllers.

**Locale file structure:**
```
config/locales/
├── en.yml                           # ActiveRecord and shared translations
├── views/
│   ├── shared.en.yml                # Navigation, buttons, confirmations
│   ├── sessions.en.yml              # Login page
│   ├── passwords.en.yml             # Password reset
│   ├── exercises.en.yml             # Exercise views
│   ├── workouts.en.yml              # Workout views
│   ├── workout_sets.en.yml          # Workout set views
│   ├── workout_reps.en.yml          # Workout rep views
│   ├── workout_routines.en.yml      # Routine views
│   ├── workout_routine_days.en.yml  # Routine day views
│   └── stats.en.yml                 # Stats dashboard
└── controllers/
    ├── sessions.en.yml              # Flash messages
    ├── passwords.en.yml
    ├── exercises.en.yml
    ├── workouts.en.yml
    ├── workout_routines.en.yml
    └── workout_routine_days.en.yml
```

**Usage:**
- Views: Use `t(".key")` for relative keys or `t("namespace.key")` for absolute keys
- Controllers: Use `I18n.t("controllers.controller_name.key")`
- Shared strings: Use `t("shared.buttons.save")`, `t("shared.confirmations.are_you_sure")`
