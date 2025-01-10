#!/bin/bash
IMAGES=$(ls -d */)
BASEDIR=$(pwd)

# Verifica parametri
if [ $# -lt 1 ] || [ $# -gt 3 ]; then
  echo "Illegal number of parameters"
  echo "Usage:"
  echo "\tbuild_images TAGNAME [IMAGE] [BRANCH]"
  echo "where TAGNAME will be used to tag the images uploaded to Docker Hub."
  exit 1
else
  TAG=$1
fi

if [ $# -ge 2 ]; then
  IMAGES=($2)
fi

BRANCH=${3:-main}  # Default branch

echo "Building Docker images for branch: $BRANCH"

# Checkout del branch specifico
git checkout $BRANCH || { echo "Failed to checkout branch $BRANCH"; exit 1; }

for I in ${IMAGES[@]}; do
  IMG=$(echo $I | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]')
  DIR=$BASEDIR/$I
  if [ -d "$DIR" ]; then
    cd $DIR
    if [ -f Dockerfile ]; then
      date > marker
      echo "Building $IMG for branch $BRANCH"
      if [[ $IMG == "generation" ]]; then
        bash $DIR/do.sh build
      else
        echo -e "\tExecuting docker build -t qbioturin/epimod-$IMG:$TAG-$BRANCH ."
        docker build -t qbioturin/epimod-$IMG:$TAG-$BRANCH .
        if [[ $? -ne 0 ]]; then
          echo "Failed to build $IMG"
          exit 1
        fi
      fi
      rm marker
      echo "Uploading $IMG"
      echo -e "\tExecuting docker push qbioturin/epimod-$IMG:$TAG-$BRANCH"
      docker push qbioturin/epimod-$IMG:$TAG-$BRANCH
      if [[ $? -ne 0 ]]; then
        echo "Failed to push $IMG"
        exit 1
      fi
    else
      echo "Dockerfile missing for image qbioturin/epimod-$IMG"
    fi
    cd $BASEDIR
  else
    echo "Skipping $I: Directory $DIR does not exist"
  fi
done
exit 0

