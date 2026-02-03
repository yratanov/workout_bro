#!/bin/bash
set -e

IMAGE_NAME="yratanov/workout_bro"

# Parse arguments
NO_CACHE=""
if [[ "$1" == "--no-cache" ]]; then
    NO_CACHE="--no-cache"
    echo "Building with --no-cache flag"
fi

# Pre-build Tailwind CSS locally before Docker build
# This is needed because the tailwindcss binary doesn't run properly
# under QEMU emulation when cross-compiling for linux/amd64 on ARM Macs
echo "Pre-building Tailwind CSS..."
bundle exec rails tailwindcss:build
if [[ ! -s "app/assets/builds/tailwind.css" ]]; then
    echo "ERROR: Failed to build tailwind.css"
    exit 1
fi
echo "Tailwind CSS built successfully"

# Check if buildx is available and supports multi-platform builds
if docker buildx version &>/dev/null && docker buildx inspect --bootstrap &>/dev/null 2>&1; then
    echo "Building Docker image for linux/amd64 using buildx..."
    docker buildx build --platform linux/amd64 -t "$IMAGE_NAME:latest" $NO_CACHE --push .
else
    echo "Building Docker image..."
    docker build -t "$IMAGE_NAME:latest" $NO_CACHE .
    echo "Pushing image..."
    docker push "$IMAGE_NAME:latest"
fi

echo "Done! Image pushed to $IMAGE_NAME:latest"
