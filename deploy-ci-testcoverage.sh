#!/bin/bash

if [ ! -d $TEST_COVERAGE_DIR ]; then
    echo "TestCoverage dir not exists..:$TEST_COVERAGE_DIR"
    exit
fi

TESTC_ARCHIVE_PATH=testcoverage

if [ $DEPLOY_LOCAL_DIR ]; then

    archiveFileName=`date +"%Y%m%d-%H%M%S"`
    if [ $CI_BUILD_ID ]; then
        archiveFileName=ci_$CI_BUILD_ID
    fi

    ARCHIVE_TESTC_DIR=$DEPLOY_LOCAL_DIR/$TESTC_ARCHIVE_PATH/$archiveFileName
    if [ ! -d $ARCHIVE_TESTC_DIR ]; then
        mkdir -p $ARCHIVE_TESTC_DIR
    fi

    echo "TestCoverage dir name:$archiveFileName"

    cp -R $TEST_COVERAGE_DIR/lcov/* $ARCHIVE_TESTC_DIR/

    if [ $DEPLOY_ENDPOINT ]; then
        echo "Visit testcoverage page from: $DEPLOY_ENDPOINT/$TESTC_ARCHIVE_PATH/$archiveFileName/index.html"
    fi
fi
