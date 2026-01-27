#!/bin/bash
set -e

IMAGE_NAME="yratanov/workout_bro"

echo "Building Docker image for linux/amd64..."
docker buildx build --platform linux/amd64 -t "$IMAGE_NAME:latest" --push .

echo "Done! Image pushed to $IMAGE_NAME:latest"
