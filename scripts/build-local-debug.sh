#!/bin/bash

export IOS_BUILD_CONFIG=Debug
export DEPLOY_LOCAL_DIR=$BUILD_HOME/deploy

bumpinfo.sh
build-project.sh
