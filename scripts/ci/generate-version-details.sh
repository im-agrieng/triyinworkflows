#!/usr/bin/env bash

set -e

CURRENT_COMMIT=$(git rev-parse --short HEAD)
echo "CURRENT_COMMIT: ${CURRENT_COMMIT}"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null && pwd)"

APP_VERSION_NAME=$(cat ${DIR}/../../RELEASE_NAME)

if [[ -n ${CI_TAG} ]]; then
    echo "Building release from tag"
    APP_VERSION_STR="$(app_version_str ${CI_TAG}) - ${APP_VERSION_NAME}"
    APK_VERSION_CODE=$(apk_version_code "${CI_TAG}" "${TRIPLET}")

    if [[ ${ALL_FILES_ACCESS} == "ON" ]]; then
        export APP_NAME="SIGPAC-Go~"
        export APP_PACKAGE_NAME="app_all_access"
    else
        export APP_NAME="SIGPAC-Go"
        export APP_PACKAGE_NAME="app"
    fi
    export APP_ICON="qfield_logo"
    export APP_VERSION="${CI_TAG}"
    export APP_VERSION_STR
    export APK_VERSION_CODE
    export APP_ENV="prod"
else
    echo "Building default configuration"
    TRIPLET_NUMBER=$(arch_to_build_number ${TRIPLET})

    if [[ ${ALL_FILES_ACCESS} == "ON" ]]; then
        export APP_NAME="SIGPAC-Go~ Dev"
        export APP_PACKAGE_NAME="app_all_access_dev"
    else
        export APP_NAME="SIGPAC-Go Dev"
        export APP_PACKAGE_NAME="app_dev"
    fi
    export APP_ICON="qfield_logo_beta"
    export APP_VERSION=""
    export APP_VERSION_STR="default-dev - ${APP_VERSION_NAME}"
    export APK_VERSION_CODE=0$((2020400 + CI_RUN_NUMBER))${TRIPLET_NUMBER}
    export APP_ENV="dev"
fi

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
