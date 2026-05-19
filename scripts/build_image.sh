#!/bin/bash

# This script builds the Docker image with improved logging
# --progress=plain: Shows full output of all commands (best for debugging)
# --no-cache: (Optional) Ensures everything is run from scratch

IMAGE_NAME="my-config"
USERNAME=${1:-tuan}

echo "Building $IMAGE_NAME for user $USERNAME with verbose logging..."

DOCKER_BUILDKIT=1 docker build \
    --progress=plain \
    --build-arg USERNAME="$USERNAME" \
    -t "$IMAGE_NAME" .
