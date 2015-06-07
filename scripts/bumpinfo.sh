#!/bin/bash


BASE_PLIST=$PROJECT_HOME/scripts/$OEMCONFIG_NAME-config/Info.plist

if [ ! -f $BASE_PLIST ]; then
    echo "Base plist not exists: $BASE_PLIST"
    exit 256
fi

####Inited by shell param####
INFOPLIST=$PROJECT_HOME/$PROJECT_NAME/Info.plist
#============================

if [ $# -gt 0 ];
then
    INFOPLIST=$1
fi

if [ ! -f $INFOPLIST ]; then
    echo "Target plist not exists: $INFOPLIST"
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

if [ "$IOS_BUILD_CONFIG" = "Debug" ]; then
    ####Override paramaters by CI env
    if [ $CI_BUILD_ID ]; then
        CFBundleVersion=$CI_BUILD_ID
    fi

    if [ $CI_BUILD_REF ]; then
        CFBundleDisplayName=${CI_BUILD_REF:0:8}
        CFBundleIdentifier=com.sample.$CI_BUILD_REF
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
