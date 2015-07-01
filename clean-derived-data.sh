#!/bin/bash

if [ -d $DERIVED_DATA_DIR ]; then
    rm -rf $DERIVED_DATA_DIR/*
fi
