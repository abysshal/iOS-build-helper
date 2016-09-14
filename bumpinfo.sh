#!/bin/bash

# $1 - source.plist
# $2 - target.plist
# $3 - debug | adhoc | release

export PLISTBUDDY=/usr/libexec/PlistBuddy

function usage {
    echo "bumpinfo.sh source.plist target.plist <debug | adhoc | release>"
}

if [ $# -lt 3 ]; then
    usage
    exit 256
fi

BASE_PLIST=$1
if [ ! -f $BASE_PLIST ]; then
    echo "Source plist not exists: $BASE_PLIST"
    exit 256
fi

INFOPLIST=$2
if [ ! -f $INFOPLIST ]; then
    echo "Target plist not exists: $INFOPLIST"
    exit 256
fi


if [ "$3" = "debug" ] || [ "$3" = "adhoc" ] || [ "$3" = "release" ]; then
    BUILD_CONFIG=$3
else
    usage
    exit 256
fi

#====================================

####Init paramaters by Base plist
CFBundleShortVersionString=`$PLISTBUDDY -c "print CFBundleShortVersionString" $BASE_PLIST`
CFBundleName=`$PLISTBUDDY -c "print CFBundleName" $BASE_PLIST`
#Inited by Env Vars in CI#
CFBundleVersion=`$PLISTBUDDY -c "print CFBundleVersion" $BASE_PLIST`
CFBundleDisplayName=`$PLISTBUDDY -c "print CFBundleDisplayName" $BASE_PLIST`
CFBundleIdentifier=`$PLISTBUDDY -c "print CFBundleIdentifier" $BASE_PLIST`
#========================

if [ "$BUILD_CONFIG" = "debug" ]; then
    ####Override paramaters by CI env
    if [ $CI_BUILD_ID ]; then
        CFBundleVersion=$CI_BUILD_ID
    fi

    if [ $CI_BUILD_REF ]; then
        CFBundleDisplayName=${CI_BUILD_REF:0:8}
        CFBundleIdentifier=com.netviewtech.$CI_BUILD_REF
    fi
fi

if [ "$BUILD_CONFIG" = "adhoc" ]; then
    ####Override paramaters by CI env
    if [ $CI_BUILD_ID ]; then
        CFBundleVersion=$CI_BUILD_ID
        CFBundleDisplayName=$CI_BUILD_ID
    fi
fi

#===============================

echo "Bumping info.plist: $INFOPLIST"
echo "#=======Param=========="
echo "CFBundleShortVersionString: $CFBundleShortVersionString"
echo "CFBundleVersion: $CFBundleVersion"
echo "CFBundleName: $CFBundleName"
echo "CFBundleDisplayName: $CFBundleDisplayName"
echo "CFBundleIdentifier: $CFBundleIdentifier"
echo "#======================"

$PLISTBUDDY -c "Set :CFBundleShortVersionString $CFBundleShortVersionString" $INFOPLIST
$PLISTBUDDY -c "Set :CFBundleVersion $CFBundleVersion" $INFOPLIST
$PLISTBUDDY -c "Set :CFBundleName $CFBundleName" $INFOPLIST
$PLISTBUDDY -c "Set :CFBundleDisplayName $CFBundleDisplayName" $INFOPLIST
$PLISTBUDDY -c "Set :CFBundleIdentifier $CFBundleIdentifier" $INFOPLIST
$PLISTBUDDY -c "Save" $INFOPLIST || exit

echo "Bump done.."
