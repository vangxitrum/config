#!/bin/bash

# This script builds the Docker image with improved logging
# --progress=plain: Shows full output of all commands (best for debugging)
# --no-cache: (Optional) Ensures everything is run from scratch

IMAGE_NAME="my-config"
USERNAME=${1:-tuan}

echo "Building $IMAGE_NAME for user $USERNAME with verbose logging..."
echo "Tip: If you encounter 'Could not resolve host' errors, you might need to check your DNS or use --network=host."

# To use host network (helps with DNS issues):
# DOCKER_BUILDKIT=1 docker build --network=host --progress=plain ...

DOCKER_BUILDKIT=1 docker build \
    --progress=plain \
    --build-arg USERNAME="$USERNAME" \
    -t "$IMAGE_NAME" .
