#!/usr/bin/env bash

set -e

CURRENT_COMMIT=$(git rev-parse --short HEAD)
echo "CURRENT_COMMIT: ${CURRENT_COMMIT}"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

APP_VERSION_NAME=$(cat ${DIR}/../../RELEASE_NAME)

# Always build with release configuration
echo "Building with release configuration"
APP_VERSION_STR="commit-${CURRENT_COMMIT} - ${APP_VERSION_NAME}"
APK_VERSION_CODE="1" # Or any default value

if [[ ${ALL_FILES_ACCESS} == "ON" ]]; then
    export APP_NAME="SIGPAC-Go~"
    export APP_PACKAGE_NAME="app_all_access"
else
    export APP_NAME="SIGPAC-Go"
    export APP_PACKAGE_NAME="app"
fi
export APP_ICON="qfield_logo"
export APP_VERSION="${CURRENT_COMMIT}"
export APP_VERSION_STR
export APK_VERSION_CODE
export APP_ENV="prod"

echo "Arch number: ${TRIPLET_NUMBER}"
echo "APP_NAME: ${APP_NAME}"
echo "APP_PACKAGE_NAME: ${APP_PACKAGE_NAME}"
echo "APP_ICON: ${APP_ICON}"
echo "APP_VERSION: ${APP_VERSION}"
echo "APP_VERSION_STR: ${APP_VERSION_STR}"
echo "ANDROID_NDK_PLATFORM : ${ANDROID_NDK_PLATFORM}"
echo "APK_VERSION_CODE: ${APK_VERSION_CODE}"

# safe guard to avoid too big number
# remove leading 0 to avoid var recognized as an octal number
if [[ ($(echo "${APK_VERSION_CODE}" | sed 's/^0*//') -gt 2000000000) ]]; then
    echo "APK_VERSION_CODE is getting too big!"
    exit 1
fi
