# Workout Bro

A self-hosted workout tracking app for strength training and running. Own your fitness data.

- Track strength workouts with sets, reps, and weights
- Log running sessions
- Create custom workout routines
- View progress statistics
- No cloud accounts or subscriptions required

## Quick Start with Docker

1. Create a `docker-compose.yml` file:

```yaml
services:
  web:
    image: yratanov/workout_bro:latest
    volumes:
      - workout_data:/rails/storage
    ports:
      - "3000:80"
    environment:
      - DISABLE_SSL=true
    restart: unless-stopped

  jobs:
    image: yratanov/workout_bro:latest
    command: bin/jobs
    volumes:
      - workout_data:/rails/storage
    environment:
      - DISABLE_SSL=true
    restart: unless-stopped
    depends_on:
      - web

volumes:
  workout_data:
```

2. Start the application:

```bash
docker compose up -d
```

3. Open http://localhost:3000

Credentials are automatically generated on first run and stored in the volume.

## Backup

```bash
docker compose cp web:/rails/storage ./backup
```

## Update

```bash
docker compose pull
docker compose up -d
```

## Custom Port

To use a different port, change `"3000:80"` to `"YOUR_PORT:80"`.
