---
name: on-prod
description: Run Rails commands on the production server. Use when the user says "on prod", "on production", "on server", or wants to query/inspect production data.
allowed-tools: Bash(ssh *), Bash(source *), Read
---

# On-Prod Skill

Execute Rails commands on the production server via SSH.

## Environment

Read `DEPLOY_SERVER_IP`, `DEPLOY_SERVER_PORT`, and `DEPLOY_REMOTE_PATH` from the `.env` file in the project root.

```bash
source .env
```

## How to run commands

The production Docker setup uses `SECRET_KEY_BASE` from `/rails/storage/.docker-env`. All Rails commands must source this file first.

**For simple one-liners:**

```bash
ssh -p $DEPLOY_SERVER_PORT $DEPLOY_SERVER_IP "cd $DEPLOY_REMOTE_PATH && docker compose exec -T web bash -c 'source /rails/storage/.docker-env && bin/rails runner \"<ruby code>\"'"
```

**For multi-line scripts (preferred):**

Write a script to the mounted `storage/` volume, execute it, then clean up:

```bash
ssh -p $DEPLOY_SERVER_PORT $DEPLOY_SERVER_IP "cat > $DEPLOY_REMOTE_PATH/storage/task.rb << 'RUBY'
<ruby code here>
RUBY
cd $DEPLOY_REMOTE_PATH && docker compose exec -T web bash -c 'source /rails/storage/.docker-env && bin/rails runner /rails/storage/task.rb'"
```

Always clean up after:

```bash
ssh -p $DEPLOY_SERVER_PORT $DEPLOY_SERVER_IP "rm -f $DEPLOY_REMOTE_PATH/storage/task.rb"
```

## Arguments

`$ARGUMENTS` describes what the user wants to do on production. Translate it into the appropriate Rails runner script.

## Important

- This is **read-only by default**. Only run write/update/delete operations if the user explicitly asks.
- Always show the output to the user.
- Always clean up the task.rb script after execution.
- The `image_processing` gem warning in output is harmless — ignore it.
- Two containers exist: `web` (Rails server) and `jobs` (Solid Queue worker). Use `web` by default.
