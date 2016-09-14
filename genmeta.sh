#!/bin/bash

# $1 - ipa output path
# $2 - bundle name
# $3 - short version str
# $4 - version number
# $5 - config name
# $6 - bundle identifier

export PLISTBUDDY=/usr/libexec/PlistBuddy

TARGET_TITLE=$2-$3-$4-$5
TARGET_IPA_NAME=$2-$3-$4-$5.ipa
TARGET_PLIST_NAME=$2-$3-$4-$5.plist
TARGET_HTML_NAME=$4-$2-$3-$5.html

TARGET_IPA=$1/$TARGET_IPA_NAME
TARGET_PLIST=$1/$TARGET_PLIST_NAME
TARGET_HTML=$1/$TARGET_HTML_NAME

TEMPLATE_PLIST="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/template.plist
TEMPLATE_HTML="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/template.html

mv $1/$2.ipa $TARGET_IPA
cp $TEMPLATE_PLIST $TARGET_PLIST
chmod 644 $TARGET_PLIST
cp $TEMPLATE_HTML $TARGET_HTML
chmod 644 $TARGET_HTML

$PLISTBUDDY -c "Set :items:0:metadata:title $TARGET_TITLE" $TARGET_PLIST
$PLISTBUDDY -c "Set :items:0:metadata:bundle-version $3" $TARGET_PLIST
$PLISTBUDDY -c "Set :items:0:metadata:bundle-identifier $6" $TARGET_PLIST
$PLISTBUDDY -c "Save" $TARGET_PLIST

sed -i "" "s#__TITLE__#${TARGET_TITLE}#g" $TARGET_HTML
