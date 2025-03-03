#!/bin/bash
set -e

# Set up the new package name
export APP_PACKAGE_NAME="app"
export APP_PACKAGE_DOMAIN="com.sigpacgo"

# Create new package directory structure
mkdir -p platform/android/src/com/sigpacgo/app

# Move Java files to new location
if [ -d "platform/android/src/ch/opengis/qfield" ]; then
    mv platform/android/src/ch/opengis/qfield/*.java platform/android/src/com/sigpacgo/app/
    # Clean up old directories if they are empty
    rmdir --ignore-fail-on-non-empty platform/android/src/ch/opengis/qfield
    rmdir --ignore-fail-on-non-empty platform/android/src/ch/opengis
    rmdir --ignore-fail-on-non-empty platform/android/src/ch
fi

# Update Java package names in files
find platform/android/src/com/sigpacgo/app -name "*.java" -type f -exec sed -i 's/package ch.opengis.qfield/package com.sigpacgo.app/g' {} +