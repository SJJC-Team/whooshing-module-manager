#!/bin/bash

name="woo-sys-manager"
OS="ubuntu24.04"

set - e

swift build --static-swift-stdlib -c release
ARCH=$(uname -m)
OUTPUT="$name-${OS}-${ARCH}-static.tar.gz"
mkdir bundle
cp .build/release/App bundle/App
cp -r .build/release/*.resources bundle/
cp pm2.config.json bundle/pm2.config.json
tar -czvf $OUTPUT bundle/
mv $OUTPUT ../