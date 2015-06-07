#!/bin/bash

export PATH=`pwd`/scripts:$PATH

####Should set this param according to Runner's env######
#export DEPLOY_ENDPOINT=https://dl.xxx.xxx
#export DEPLOY_LOCAL_DIR=/Users/cirunner/Sites
####==================================================

export TASK_NAME=deploy

do-run.sh $@ || exit
