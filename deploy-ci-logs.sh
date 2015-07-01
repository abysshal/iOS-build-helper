#!/bin/bash

export PROJECT_HOME=`pwd`
export BUILD_HOME=$PROJECT_HOME/build
export LOGS_BUILD_DIR=$BUILD_HOME/logs

if [ ! -d $LOGS_BUILD_DIR ]; then
    echo "Logs dir not exists..:$LOGS_BUILD_DIR"
    exit
fi

LOGS_ARCHIVE_PATH=logs/build

if [ $DEPLOY_LOCAL_DIR ]; then
    ARCHIVE_LOGS_DIR=$DEPLOY_LOCAL_DIR/$LOGS_ARCHIVE_PATH
    if [ ! -d $ARCHIVE_LOGS_DIR ]; then
        mkdir -p $ARCHIVE_LOGS_DIR
    fi

    archiveFileName=`date +"%Y%m%d-%H%M%S"`
    if [ $CI_BUILD_ID ]; then
        archiveFileName=ci_$CI_BUILD_ID
    fi
    archiveFileName=$archiveFileName.tar.gz

    echo "Logs archive name:$archiveFileName"

    cd $LOGS_BUILD_DIR
    tar czf $ARCHIVE_LOGS_DIR/$archiveFileName ./ || exit

    echo "Logs archived.."

    if [ $DEPLOY_ENDPOINT ]; then
        echo "Visit logs archive from: $DEPLOY_ENDPOINT/$LOGS_ARCHIVE_PATH/$archiveFileName"
    fi
fi
