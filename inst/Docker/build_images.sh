#!/bin/bash
IMAGES=($(ls -d */))
PWD=$(pwd) 
if [ $# -ne 1 ]; then
	echo "Illegal number of parameters"
	echo "Usage:"
	echo "\tbuild_images TAGNAME"
	echo "where TAGNAME will be used to tag the images uploaded to Docker Hub."
	exit 1
else
	TAG=$1
fi
for I in $IMAGES; do
	echo "$I"
	# Make all letters lowercase and remove the ending babcslash
	IMG=$(echo $I | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]')
	DIR=$PWD/$I
	cd $DIR
	if [ -f $DIR/Dockerfile ]; then
		date > marker
		echo "Building $IMG"
		echo "\tExecuting docker build -t qbioturin/epimod-$IMG:$TAG ."
		RET=$(docker build -t qbioturin/epimod-$IMG:$TAG .)
		if [[ $RET -eq 0 ]]; then
			exit 0
		fi	
		rm marker
		echo "Uploading $IMG"
	       	echo "\tExecuting docker push qbioturin/epimod-$IMG:$TAG"
		RET=$(docker push qbioturin/epimod-$IMG:$TAG)
		if [[ $RET -eq 0 ]]; then
			exit 0
		fi	
	else
		echo "Dockerfile missing for image qbioturin/epimod-$IMG"
	fi
	cd $PWD
done
exit 0
