#!/bin/bash

DERIVED_DATA=~/Library/Developer/Xcode/DerivedData

FILE_PATTERN="*"

if [ $# -gt 0 ];then
    FILE_PATTERN=$1
fi

echo "DerivedData to clean: $DERIVED_DATA/$FILE_PATTERN"

rm -rf $DERIVED_DATA/$FILE_PATTERN
