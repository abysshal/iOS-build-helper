#!/bin/bash

export PLISTBUDDY=/usr/libexec/PlistBuddy

export PROJECT_HOME=`pwd`
export BUILD_HOME=$PROJECT_HOME/build
export IPA_BUILD_DIR=$BUILD_HOME/ipa-build
export LOGS_BUILD_DIR=$BUILD_HOME/logs
export DERIVED_DATA_DIR=$BUILD_HOME/derived-data
export TEST_COVERAGE_DIR=$BUILD_HOME/test-coverage

scripts="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export PATH=$scripts:$PATH
