#!/bin/bash

export IOS_BUILD_CONFIG=Debug
export LOG_TO_FILE=yes

pod update
cleanall.sh
bumpinfo.sh
build-project.sh
