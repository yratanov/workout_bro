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

```bash
bin/rails test                           # Run all tests
bin/rails test:models                    # Run model tests only
bin/rails test:system                    # Run system tests (Selenium)
bin/rails test:components                # Run ViewComponent tests
bin/rails test test/models/user_test.rb  # Run a single test file
```

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
