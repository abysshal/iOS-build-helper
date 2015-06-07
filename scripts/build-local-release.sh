#!/bin/bash

export IOS_BUILD_CONFIG=Release
export DEPLOY_LOCAL_DIR=$BUILD_HOME/deploy

pod update
cleanall.sh $PROJECT_NAME-*
bumpinfo.sh
build-project.sh
