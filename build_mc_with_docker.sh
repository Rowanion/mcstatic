#!/bin/bash

# build the docker image
sudo docker build -t mc-builder .

# build mc and get the file
docker run --rm -v ${PWD}:/output mc-builder bash -c "/build_mc.sh && cp /build/*.AppImage /output/"
