#!/bin/bash
if [[ $# -lt 1 ]]; then
  echo "No parameters provided"
  exit 1
else
  version="$1"
fi

docker login
docker buildx use mybuilder
docker buildx build --no-cache --platform linux/amd64,linux/arm64/v8 -t ggilman/hamclock:latest -t ggilman/hamclock:"$version" --push .
