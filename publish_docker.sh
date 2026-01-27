#!/bin/bash
set -e

IMAGE_NAME="yratanov/workout_bro"

# Check if buildx is available and supports multi-platform builds
if docker buildx version &>/dev/null && docker buildx inspect --bootstrap &>/dev/null 2>&1; then
    echo "Building Docker image for linux/amd64 using buildx..."
    docker buildx build --platform linux/amd64 -t "$IMAGE_NAME:latest" --push .
else
    echo "Building Docker image..."
    docker build -t "$IMAGE_NAME:latest" .
    echo "Pushing image..."
    docker push "$IMAGE_NAME:latest"
fi

echo "Done! Image pushed to $IMAGE_NAME:latest"
