---
name: deploy
description: Commit, push, build Docker image, and deploy to production server. Use when the user says "deploy", "commit/push/publish/deploy", or wants to ship changes.
allowed-tools: Bash(git *), Bash(./publish_docker.sh *), Bash(ssh *), Read, Grep, Glob
---

# Deploy Skill

Commit all changes, push to remote, build and publish Docker image, then deploy to the production server.

## Environment Variables

Read `DEPLOY_SERVER_IP`, `DEPLOY_SERVER_PORT`, and `DEPLOY_REMOTE_PATH` from the `.env` file in the project root.

## Steps

### 1. Load environment

```bash
source .env
```

Use `$DEPLOY_SERVER_IP`, `$DEPLOY_SERVER_PORT`, and `$DEPLOY_REMOTE_PATH` throughout.

### 2. Commit

- Run `git status` (never use `-uall`), `git diff` (staged + unstaged), and `git log --oneline -5` in parallel
- Analyze all changes and draft a concise commit message focusing on "why" not "what"
- Stage relevant files by name (never `git add -A` or `git add .`)
- Do NOT commit files containing secrets (`.env`, credentials, etc.)
- Commit with message ending with: `Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>`
- Use a HEREDOC for the commit message

### 3. Push

```bash
git push
```

### 4. Build and publish Docker image

```bash
./publish_docker.sh
```

This builds the image and pushes it to Docker Hub.

### 5. Deploy to server

```bash
ssh -p $DEPLOY_SERVER_PORT $DEPLOY_SERVER_IP "cd $DEPLOY_REMOTE_PATH && docker compose pull && docker compose up -d"
```

### 6. Report

Confirm that all steps completed successfully: commit hash, push status, image published, containers restarted.

## Arguments

- `$ARGUMENTS` - Optional commit message override. If provided, use it as the commit message instead of auto-generating one.

## Important

- If there are no changes to commit, skip straight to build/deploy
- If the build fails, stop and report the error — do not deploy
- Never force push
- Never skip git hooks
