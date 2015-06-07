#!/bin/bash

export PATH=`pwd`/scripts:$PATH

####Config#####
export PROJECT_NAME=myproject
export OEMCONFIG_NAME=myproject
#=================

export TASK_NAME=build

do-run.sh $@ || exit
