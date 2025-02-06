#!/bin/bash

# Get the version from the command line
if [[ -z "$1" ]]; then
  echo "ERROR: Version must be provided as a command-line argument."
  exit 1
fi

version="$1"

IMAGE_NAME="ggilman/hamclock"
EXE_NAME="hamclock-1600x960"  # Set the executable name as a variable
BUILDER_NAME="mybuilder" # Name of your buildx builder
PLATFORMS="linux/amd64,linux/arm64/v8"

# Docker Login
docker login  # You'll be prompted for username and password

# Use the specified buildx builder
docker buildx use "$BUILDER_NAME"

# Check if builder is correctly set.
if ! docker buildx ls | grep -q "$BUILDER_NAME\*"; then
  echo "ERROR: Failed to switch to buildx builder '$BUILDER_NAME'."
  exit 1
fi

#docker buildx build --platform "$PLATFORMS" -t "$IMAGE_NAME:latest" -t "$IMAGE_NAME:$version" --load .
echo "Building $IMAGE_NAME:$version"
docker build --tag "$IMAGE_NAME:$version" .

if [[ $? -eq 0 ]]; then
  echo "Docker build successful."

  # Create a temporary container to check for the executable
  echo  "Loading container $IMAGE_NAME:$version for testing"
  TEST_COMMAND="docker run --rm ${IMAGE_NAME}:${version} sh -c 'if command -v ${EXE_NAME} >/dev/null 2>&1; then exit 0; else exit 1; fi'"

  # Check if the executable exists inside the container
  if eval "${TEST_COMMAND}"; then
    echo "Executable '$EXE_NAME' found inside the container."
    echo "Performing final build and push."
    docker buildx build --platform "$PLATFORMS" -t "$IMAGE_NAME:latest" -t "$IMAGE_NAME:$version" --push .
    if [[ $? -eq 0 ]]; then
      echo "Push of versioned tag successful."
    else
      echo "ERROR: Push of versioned tag failed."
      exit 1
    fi

  else
    echo "ERROR: Executable '$EXE_NAME' NOT found inside the container."
    exit 1
  fi
else
  echo "ERROR: Docker build failed."
  exit 1
fi

echo "Build and push complete."
