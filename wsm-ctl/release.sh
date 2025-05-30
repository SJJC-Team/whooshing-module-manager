#!/bin/bash

name="woo-sys-wsm"
OS="ubuntu24.04"

set - e

swift build --static-swift-stdlib -c release
ARCH=$(uname -m)
OUTPUT="$name-${OS}-${ARCH}-static.tar.gz"
mkdir wsm
cp .build/release/wsm wsm/wsm
cp -r .build/release/*.resources wsm/
tar -czvf $OUTPUT wsm/
mv $OUTPUT ../