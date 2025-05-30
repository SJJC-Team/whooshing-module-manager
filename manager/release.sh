#!/bin/bash

set - e

swift build --static-swift-stdlib -c release
ARCH=$(uname -m)
OS="ubuntu24.04"
OUTPUT="manager-${OS}-${ARCH}-static.tar.gz"
mkdir bundle
cp .build/release/App bundle/App
cp -r .build/release/whooshing.toolbox-basic_Whooshing.resources bundle/whooshing.toolbox-basic_Whooshing.resources
cp pm2.config.json bundle/pm2.config.json
tar -czvf $OUTPUT bundle/
mv $OUTPUT ../