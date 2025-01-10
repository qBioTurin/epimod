#!/bin/bash
IMAGES=$(ls -d */)
BASEDIR=$(pwd)

# Verifica parametri
if [ $# -eq 0 ] || [ $# -ge 4 ]; then
  echo "Illegal number of parameters"
  echo "Usage:"
  echo "\tbuild_images TAGNAME IMAGE [BRANCH]"
  echo "where TAGNAME will be used to tag the images uploaded to Docker Hub."
  exit 1
else
  TAG=$1
fi

if [ $# -eq 2 ]; then
  IMAGES=($2)
fi

BRANCH=${3:-main}  # Default branch

for I in ${IMAGES[@]}; do
  IMG=$(echo $I | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]')
  DIR=$BASEDIR/$I
  cd $DIR
  if [ -f $DIR/Dockerfile ]; then
    date > marker
    echo "Building $IMG for branch $BRANCH"
    if [[ $IMG == "Generation" ]]; then
      bash $DIR/do.sh build
    else
      echo -e "\tExecuting docker build -t qbioturin/epimod-$IMG:$TAG-$BRANCH ."
      docker build -t qbioturin/epimod-$IMG:$TAG-$BRANCH .
      if [[ $? -ne 0 ]]; then
        exit 1
      fi
    fi
    rm marker
    echo "Uploading $IMG"
    echo -e "\tExecuting docker push qbioturin/epimod-$IMG:$TAG-$BRANCH"
    docker push qbioturin/epimod-$IMG:$TAG-$BRANCH
    if [[ $? -ne 0 ]]; then
      exit 1
    fi
  else
    echo "Skipping $I: Dockerfile missing in $DIR"
  fi
  cd $BASEDIR
done
exit 0

