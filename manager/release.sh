#!/bin/bash

LABEL=$1
SWIFT_VERSION=$2

set - e

name="woo-sys-manager"

# ------------------------------------------------

# Expand system name and version
OS_NAME=""
OS_VERSION=""

UNAME_S=$(uname -s)

case "$UNAME_S" in
  Darwin)
    # macOS or iOS (simulator or device via cross-compile)
    if [[ "$(uname -m)" == "x86_64" || "$(uname -m)" == "arm64" ]]; then
      PRODUCT_NAME=$(sw_vers -productName)
      PRODUCT_VERSION=$(sw_vers -productVersion)
      if [[ "$PRODUCT_NAME" == "macOS" || "$PRODUCT_NAME" == "Mac OS X" ]]; then
        OS_NAME="macos"
        OS_VERSION="$PRODUCT_VERSION"
      else
        OS_NAME="ios"  # fallback
        OS_VERSION="unknown"
      fi
    fi
    ;;
  Linux)
    # Check for Ubuntu, Debian, etc.
    if command -v lsb_release >/dev/null 2>&1; then
      OS_NAME=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
      OS_VERSION=$(lsb_release -rs)
    elif [ -f /etc/os-release ]; then
      # Fallback for containers or Alpine
      . /etc/os-release
      OS_NAME=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
      OS_VERSION=$VERSION_ID
    else
      OS_NAME="linux"
      OS_VERSION="unknown"
    fi
    ;;
  *)
    OS_NAME="unknown"
    OS_VERSION="unknown"
    ;;
esac

# Format with underscores and lowercase
OS_NAME_CLEAN=$(echo "$OS_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
OS_VERSION_CLEAN=$(echo "$OS_VERSION" | tr '[:upper:]' '[:lower:]' | tr '.' '-')

OS="${OS_NAME_CLEAN}-${OS_VERSION_CLEAN}"

# ------------------------------------------------

swift build --static-swift-stdlib -c release
ARCH=$(uname -m)
OUTPUT="$name-${OS}-${ARCH}-${LABEL}-${SWIFT_VERSION}.tar.gz"

mkdir bundle
cp .build/release/App bundle/App
cp -r .build/release/*.resources bundle/
cp pm2.config.json bundle/pm2.config.json
tar -czvf $OUTPUT bundle/
mv $OUTPUT ../