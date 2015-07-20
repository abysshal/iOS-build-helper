#!/bin/bash

function usage {
    echo "runtool.sh <build | archive | itms | test>  <local | ci> <debug | release>"
}

#============================

if [ $# -lt 3 ]; then
    usage
    exit 256
fi

if [ "$1" = "build" ] || [ "$1" = "archive" ] || [ "$1" = "itms" ] || [ "$1" = "test" ]; then
    RUN_ACTION=$1
else
    usage
    exit 256
fi

if [ "$2" = "local" ] || [ "$2" = "ci" ]; then
    RUN_ENV=$2
else
    usage
    exit 256
fi

if [ "$3" = "debug" ] || [ "$3" = "release" ]; then
    RUN_BUILD_CONFIG=$3
else
    usage
    exit 256
fi

#================================

if [ ! -d $IPA_BUILD_DIR ]; then
	mkdir -p $IPA_BUILD_DIR
fi

if [ ! -d $LOGS_BUILD_DIR ]; then
	mkdir -p $LOGS_BUILD_DIR
fi

if [ ! -d $TEST_COVERAGE_DIR ]; then
	mkdir -p $TEST_COVERAGE_DIR
fi

#=================================

LOG_TO_FILE=no

if [ "$RUN_ACTION" = "build" ]; then
    echo "Build ipa for Project Home: $PROJECT_HOME"

    if [ "$RUN_ENV" = "ci" ]; then
        LOG_TO_FILE=yes
    fi

    if [ "$RUN_BUILD_CONFIG" = "release" ] || [ "$RUN_ENV" = "ci" ]; then
        clean-derived-data.sh
    fi

    bumpinfo.sh $INFO_PLIST_SOURCE $PROJECT_HOME/$XCODE_PROJECT/Info.plist $RUN_BUILD_CONFIG || exit

    build_cmd='ipa-build.sh '${PROJECT_HOME}' -w -s '${XCODE_SCHEME}' -n -p iOS'
    if [ "$RUN_BUILD_CONFIG" = "debug" ]; then
        build_cmd=${build_cmd}' -c Debug'
    fi
    if [ "$RUN_BUILD_CONFIG" = "release" ]; then
        build_cmd=${build_cmd}' -c Release'
    fi
    if [ "$LOG_TO_FILE" = "yes" ]; then
        build_cmd=${build_cmd}' -l'
    fi
    echo "Build cmd:$build_cmd"
    $build_cmd || exit
    echo "Build ipa done.."

    ipa-helper.sh summary $IPA_BUILD_DIR/*.ipa || exit
    ipa-helper.sh verify $IPA_BUILD_DIR/*.ipa || exit
    echo "Verify done.."

    if [ "$RUN_ENV" = "ci" ]; then
        deploy-ci-ipa.sh || exit
    fi
    echo "ITMS done.."

    exit
fi

if [ "$RUN_ACTION" = "archive" ]; then
    echo "Archive project for Project Home: $PROJECT_HOME"

    clean-derived-data.sh
    bumpinfo.sh $INFO_PLIST_SOURCE $PROJECT_HOME/$XCODE_PROJECT/Info.plist $RUN_BUILD_CONFIG || exit

    build_cmd='ipa-build.sh '${PROJECT_HOME}' -a -w -s '${XCODE_SCHEME}' -n -p iOS'
    if [ "$RUN_BUILD_CONFIG" = "release" ]; then
        build_cmd=${build_cmd}' -c Release'
    fi
    if [ "$LOG_TO_FILE" = "yes" ]; then
        build_cmd=${build_cmd}' -l'
    fi
    $build_cmd || exit
    echo "Archive done.."

    exit
fi

if [ "$RUN_ACTION" = "itms" ]; then
    if [ "$RUN_ENV" = "local" ]; then
        if [ $DEPLOY_LOCAL_DIR ]; then
            echo "Deploy local dir:$DEPLOY_LOCAL_DIR"
        else
            export DEPLOY_LOCAL_DIR=$BUILD_HOME/deploy
        fi
    fi

    if [ "$RUN_ENV" = "ci" ]; then
        deploy-ci-ipa.sh || exit
    fi

    echo "ITMS done.."

    exit
fi

if [ "$RUN_ACTION" = "test" ]; then

    xctool \
    -workspace $XCODE_WORKSPACE.xcworkspace \
    -scheme $XCODE_SCHEME \
    -sdk iphonesimulator \
    -derivedDataPath $DERIVED_DATA_DIR \
    -reporter plain:$LOGS_BUILD_DIR/xctest.log \
    test || exit

    grep "TEST SUCCEEDED" -i $LOGS_BUILD_DIR/xctest.log

    coverage_cmd="$PROJECT_HOME/Pods/XcodeCoverage/getcov -o $TEST_COVERAGE_DIR"

    if [ "$RUN_ENV" = "local" ]; then
        coverage_cmd=$coverage_cmd' -s'
        $coverage_cmd || exit
    fi

    if [ "$RUN_ENV" = "ci" ]; then
        $coverage_cmd > $LOGS_BUILD_DIR/getcov.log 2>&1 || exit
	tail -n 3 $LOGS_BUILD_DIR/getcov.log | grep "lines" | awk -F' ' '{print "covered " $2;}'
    fi

    echo "Export TestCoverage report done.."

    if [ "$RUN_ENV" = "ci" ]; then
        deploy-ci-testcoverage.sh || exit
    fi

    echo "Deploy ci TestCoverage done.."

    exit
fi
