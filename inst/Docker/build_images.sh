#!/bin/bash
BASEDIR=$(pwd)
CONTAINERS_DIR=$(dirname "$BASEDIR")/Containers

# Default image list: all Docker sub-folders + display
ALL_IMAGES=(Analysis Calibration Generation Sensitivity Display)
IMAGES=("${ALL_IMAGES[@]}")

PLATFORMS="linux/amd64,linux/arm64"

# Verifica parametri
if [ $# -lt 1 ] || [ $# -gt 3 ]; then
  echo "Illegal number of parameters"
  echo "Usage:"
  echo -e "\tbuild_images TAGNAME [IMAGE] [BRANCH]"
  echo "where TAGNAME will be used to tag the images uploaded to Docker Hub."
  echo "Available images: ${ALL_IMAGES[*]}"
  exit 1
fi

TAG=$1

if [ $# -ge 2 ]; then
  IMAGES=("$2")
fi

BRANCH=${3:-main}

echo "Building Docker images for branch: $BRANCH (platforms: $PLATFORMS)"

# Ensure a multi-platform buildx builder is available
if ! docker buildx inspect multibuilder > /dev/null 2>&1; then
  echo "Creating multi-platform buildx builder..."
  docker buildx create --name multibuilder --use
else
  docker buildx use multibuilder
fi

for I in "${IMAGES[@]}"; do
  IMG=$(echo "$I" | tr '[:upper:]' '[:lower:]')

  # Display lives in inst/Containers/Display, everything else in inst/Docker/<name>
  if [[ "$IMG" == "display" ]]; then
    DIR="$CONTAINERS_DIR/Display"
  else
    DIR="$BASEDIR/$I"
  fi

  if [ ! -d "$DIR" ]; then
    echo "Skipping $I: Directory $DIR does not exist"
    continue
  fi

  cd "$DIR"

  if [ ! -f Dockerfile ]; then
    echo "Dockerfile missing for image qbioturin/epimod-$IMG"
    cd "$BASEDIR"
    continue
  fi

  IMAGE_TAG="qbioturin/epimod-$IMG:$TAG"
  echo "Building $IMAGE_TAG ..."

  if [[ "$IMG" == "generation" ]] || [[ "$IMG" == "display" ]]; then
    # generation: custom multi-stage build; display: rocker/shiny is amd64-only
    echo -e "\tBuilding $IMAGE_TAG (linux/amd64 only)"
    docker buildx build \
      --platform linux/amd64 \
      --tag "$IMAGE_TAG" \
      --push \
      .
  else
    docker buildx build \
      --platform "$PLATFORMS" \
      --tag "$IMAGE_TAG" \
      --push \
      .
  fi

  if [[ $? -ne 0 ]]; then
    echo "Failed to build/push $IMG"
    exit 1
  fi

  echo "Done: $IMAGE_TAG"
  cd "$BASEDIR"
done

echo "All images built and pushed successfully."
exit 0

