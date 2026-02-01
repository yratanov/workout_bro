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

Uses RSpec with Capybara for feature tests.

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
- `spec/fixtures/` - Test data fixtures

**Spec file conventions:**
- Do NOT include `require "rails_helper"` - it's loaded automatically
- Use `describe` not `RSpec.describe`
- Do NOT use `type:` declarations (e.g., `type: :request`) - spec type is inferred from directory
- Use `fixtures :all` to load all fixtures
- Use descriptive fixture names (e.g., `users(:john)`, not `users(:one)`)

## Code Quality

```bash
bin/rubocop            # Lint (Omakase Rails style)
bin/rubocop -A         # Auto-fix offenses
bin/brakeman           # Security scan
bundle exec annotaterb # Add schema annotations to models
```

**After editing Ruby files, always run `npx prettier --write <changed_files>` to format, then `bin/rubocop -A <changed_files>` to auto-fix style issues.**

**After editing JavaScript files, always run `npx prettier --write <changed_files>` to format.**

**After editing ERB files, always run `bundle exec erb-format --write <changed_files>` to format.**

## JavaScript Conventions

**Always prefer async/await over .then() chains for asynchronous code.** This improves readability and error handling.

```javascript
// Preferred
async onSubmit(event) {
  const response = await fetch(url, { method: "POST" });
  const html = await response.text();
  // process response
}

// Avoid
onSubmit(event) {
  fetch(url, { method: "POST" })
    .then((response) => response.text())
    .then((html) => { /* process response */ });
}
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

**Important: All translations must be added to both locales (en and ru).** When adding new translation keys, always create or update both the `.en.yml` and `.ru.yml` files.

## UI Components

**Always use the `button` helper instead of raw HTML `<button>` or `<a>` tags for buttons/links.**

```erb
# Button (default type)
<%= button t(".save"), style: "primary" %>

# Link styled as button
<%= button t(".view"), type: "link", style: "primary", route: some_path %>

# Delete button with confirmation
<%= button t(".delete"), style: "danger", method: :delete, route: some_path,
    data: { turbo_confirm: t(".confirm") } %>

# Button with Stimulus action
<%= button t(".close"), style: "outlined", data: { action: "click->modal#close" } %>
```

**Available styles:** `primary`, `success`, `danger`, `warning`, `default`, `outlined`, `link`, `link_danger`, `link_hover_danger`

**Available sizes:** `default`, `lg`

**Use `stat_card` for displaying labeled statistics (label + value):**

```erb
# Default size (for summary pages)
<%= stat_card label: t(".total_volume") do %>
  <%= format_volume(@summary.total_volume) %>
<% end %>

# Small size (for modals)
<%= stat_card label: t(".sets"), size: :sm do %>
  <%= @summary.total_sets %>
<% end %>
```

**Available sizes:** `:lg` (default), `:sm`

**Use `empty_state` for empty state messages with icon/emoji and optional action:**

```erb
# With emoji
<%= empty_state emoji: "💪", message: t(".no_exercises") %>

# With icon
<%= empty_state icon: "trophy", message: t(".no_records"), hint: t(".hint") %>

# With title and action button
<%= empty_state icon: "dumbbell", message: t(".no_routines") do %>
  <%= button t(".create"), route: new_path, style: "primary", type: "link" %>
<% end %>
```

**Use `page_header` for page titles with optional action buttons:**

```erb
# Title only
<%= page_header title: t(".title") %>

# Title with action button
<%= page_header title: t(".title") do %>
  <%= button t(".new"), route: new_path, style: "primary", type: "link" %>
<% end %>
```

**Use `section_header` for section headings with optional icons:**

```erb
<%= section_header title: t(".notes"), icon: "note" %>
<%= section_header title: t(".new_prs"), icon: "trophy", icon_class: "text-yellow-400", title_class: "text-yellow-400 font-semibold" %>
```

**Use `notes_display` for displaying notes with edit functionality:**

```erb
<%= notes_display notes: @workout.notes, edit_path: notes_modal_workout_path(@workout), empty_text: t(".add_notes") %>
```

**Use `modal` for modal dialogs:**

```erb
<%= modal title: t(".title"), size: "md" do %>
  <!-- Modal content -->
<% end %>
```

**Available modal sizes:** `sm`, `md` (default), `lg`, `xl`

## View Guidelines

**Keep views simple - avoid complex Ruby logic in ERB templates.** Views should only contain:
- Simple conditionals (`if`/`else` for showing/hiding elements)
- Iterating over collections
- Calling helper methods
- Rendering partials

**Move complex logic to helpers or presenters:**
- Data querying and filtering → helper methods
- Business logic calculations → model methods or service objects
- Complex conditionals → helper methods that return simple values

```erb
# Bad - complex logic in view
<%
  items = Model.where(complex: conditions).order(:position)
  filtered = items.select { |i| i.some_condition? && !other_ids.include?(i.id) }
  result = filtered.first&.some_method || default_value
%>

# Good - logic extracted to helper
<% result = calculated_result_for(@model) %>
```
