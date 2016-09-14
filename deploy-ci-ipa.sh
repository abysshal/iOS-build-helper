#!/bin/bash

# $1 - build output path

if [ $DEPLOY_ENDPOINT ]; then
	echo "Deploy Endpoint: $DEPLOY_ENDPOINT"
else
	echo "Error: the param DEPLOY_ENDPOINT does not exists.."
	exit 256
fi

DEPLOY_PATH_ROOT=ota/`date +"%Y%m"`
DEPLOY_PATH_RES=res

if [ $1 ]; then
	ipaFileName=`basename $1/*.ipa`
	plistFileName=`basename $1/*.plist`
	htmlFileName=`basename $1/*.html`
	ipaFile=$1/$ipaFileName
	plistFile=$1/$plistFileName
	htmlFile=$1/$htmlFileName
else
	ipaFileName=`basename $IPA_BUILD_DIR/*.ipa`
	plistFileName=`basename $IPA_BUILD_DIR/*.plist`
	htmlFileName=`basename $IPA_BUILD_DIR/*.html`
	ipaFile=$IPA_BUILD_DIR/$ipaFileName
	plistFile=$IPA_BUILD_DIR/$plistFileName
	htmlFile=$IPA_BUILD_DIR/$htmlFileName
fi

IPA_URL=$DEPLOY_ENDPOINT/$DEPLOY_PATH_ROOT/$DEPLOY_PATH_RES/$ipaFileName
PLIST_URL=$DEPLOY_ENDPOINT/$DEPLOY_PATH_ROOT/$DEPLOY_PATH_RES/$plistFileName

$PLISTBUDDY -c "Set :items:0:assets:0:url $IPA_URL" $plistFile
$PLISTBUDDY -c "Save" $plistFile

sed -i "" "s#__IPA_URL__#${IPA_URL}#g" $htmlFile
sed -i "" "s#__PLIST_URL__#${PLIST_URL}#g" $htmlFile

if [ $DEPLOY_LOCAL_DIR ]; then

	localRes=$DEPLOY_LOCAL_DIR/$DEPLOY_PATH_ROOT/$DEPLOY_PATH_RES
	if [ ! -d $localRes ];then
		mkdir -p $localRes
	fi

	cp $ipaFile $localRes/
	cp $plistFile $localRes/
    cp $htmlFile $DEPLOY_LOCAL_DIR/$DEPLOY_PATH_ROOT/

    echo "Deploy done.."
	echo "To install ipa, visit: $DEPLOY_ENDPOINT/$DEPLOY_PATH_ROOT/$htmlFileName"
else
    echo "Error: the param DEPLOY_LOCAL_DIR does not exists.."
    exit 256
fi
