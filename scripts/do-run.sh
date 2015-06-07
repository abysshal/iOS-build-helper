#!/bin/bash

function usage {
    echo "run-${TASK_NAME}.sh <-local | -ci> <-debug | -release>"
}

if [ $# -lt 2 ]; then
    usage
    exit 256
fi

run_cmd=${TASK_NAME}

if [ "$1" = "-local" ] || [ "$1" = "-ci" ]; then
    run_cmd=${run_cmd}$1
else
    usage
    exit 256
fi

if [ "$2" = "-debug" ] || [ "$2" = "-release" ]; then
    run_cmd=${run_cmd}$2
else
    usage
    exit 256
fi

run_cmd=${run_cmd}.sh

#=============================================

export PLISTBUDDY=/usr/libexec/PlistBuddy

export PROJECT_HOME=`pwd`
export BUILD_HOME=$PROJECT_HOME/build
export IPA_BUILD_DIR=$BUILD_HOME/ipa-build

export PATH=$PROJECT_HOME/scripts:$PATH

echo "run-${TASK_NAME}: $run_cmd"

$run_cmd || exit

echo "run-${TASK_NAME} done.."
