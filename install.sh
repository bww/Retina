#!/usr/bin/env bash

# exit on error
set -e
# build the Retina target and install it
xcodebuild -target Retina -configuration Release DSTROOT=/ install

