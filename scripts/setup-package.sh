#!/bin/bash
set -e

# Export package variables
export APP_NAME="SIGPAC-Go"
export APP_PACKAGE_NAME="app"
export APP_PACKAGE_DOMAIN="com.sigpacgo"

# Make these available to subsequent steps
echo "APP_NAME=${APP_NAME}" >> $GITHUB_ENV
echo "APP_PACKAGE_NAME=${APP_PACKAGE_NAME}" >> $GITHUB_ENV
echo "APP_PACKAGE_DOMAIN=${APP_PACKAGE_DOMAIN}" >> $GITHUB_ENV