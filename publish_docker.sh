#!/bin/bash
set -e

IMAGE_NAME="yratanov/workout_bro"

echo "Building Docker image..."
docker build -t "$IMAGE_NAME" .

echo "Pushing to Docker Hub..."
docker push "$IMAGE_NAME:latest"

echo "Done! Image pushed to $IMAGE_NAME:latest"
