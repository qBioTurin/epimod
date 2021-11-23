#!/bin/bash
<<<<<<< HEAD
#IMAGES=$(ls -d */)
IMAGES=(Analysis Calibration Sensitivity)
BASEDIR=$(pwd) 
=======
# IMAGES=$(ls -d */)
# IMAGES=(Calibration)
IMAGES=(Sensitivity Calibration Analysis)
BASEDIR=$(pwd)
>>>>>>> dev-de
if [ $# -ne 1 ]; then
	echo "Illegal number of parameters"
	echo "Usage:"
	echo "\tbuild_images TAGNAME"
	echo "where TAGNAME will be used to tag the images uploaded to Docker Hub."
	exit 1
else
	TAG=$1
fi
<<<<<<< HEAD
=======
# for I in $IMAGES; do
>>>>>>> dev-de
for I in ${IMAGES[@]}; do
	# Make all letters lowercase and remove the ending babcslash
	IMG=$(echo $I | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]')
	DIR=$BASEDIR/$I
	cd $DIR
	if [ -f $DIR/Dockerfile ]; then
		date > marker
		echo "Building $IMG"
		echo -e "\tExecuting docker build -t qbioturin/epimod-$IMG:$TAG ."
		docker build -t qbioturin/epimod-$IMG:$TAG .
		if [[ $? -ne 0 ]]; then
			exit 0
<<<<<<< HEAD
		fi	
		rm marker
		echo "Uploading $IMG"
	       	echo -e "\tExecuting docker push qbioturin/epimod-$IMG:$TAG"
		#docker push qbioturin/epimod-$IMG:$TAG
		if [[ $? -ne 0 ]]; then
			exit 0
		fi	
=======
		fi
		rm marker
	 	echo "Uploading $IMG"
	        	echo -e "\tExecuting docker push qbioturin/epimod-$IMG:$TAG"
	 	docker push qbioturin/epimod-$IMG:$TAG
	 	if [[ $? -ne 0 ]]; then
	 		exit 0
	 	fi
>>>>>>> dev-de
	else
		echo "Dockerfile missing for image qbioturin/epimod-$IMG"
	fi
	cd $BASEDIR
done
exit 0
