#!/bin/bash


echo "Build ipa for Project Home: $PROJECT_HOME"

build_cmd='ipa-build.sh '${PROJECT_HOME}' -w -s '${PROJECT_NAME}' -n -p iOS'

if [ $IOS_BUILD_CONFIG ]; then
    build_cmd=${build_cmd}' -c '${IOS_BUILD_CONFIG}
fi

if [ $LOG_TO_FILE ]; then
    build_cmd=${build_cmd}' -l'
fi

$build_cmd || exit

echo "Build ipa done.."

ipa-helper.sh summary $IPA_BUILD_DIR/*.ipa || exit

ipa-helper.sh verify $IPA_BUILD_DIR/*.ipa || exit

echo "Verify done.."
