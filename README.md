## [Workout Bro](https://yratanov.github.io/workout_bro/)

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
      - ./storage:/rails/storage
    ports:
      - "3000:80"
    environment:
      - DISABLE_SSL=true
    restart: unless-stopped

  jobs:
    image: yratanov/workout_bro:latest
    command: bin/jobs
    volumes:
      - ./storage:/rails/storage
    environment:
      - DISABLE_SSL=true
    restart: unless-stopped
    depends_on:
      - web
```

2. Create the storage directory:

```bash
mkdir -p storage
```

3. Start the application:

```bash
docker compose up -d
```

4. Open http://localhost:3000

## Backup

Your data is stored in the `./storage` directory. Simply backup this folder:

```bash
cp -r storage backup
```

## Update

```bash
docker compose pull
docker compose up -d
```

## Custom Port

To use a different port, change `"3000:80"` to `"YOUR_PORT:80"`.
