#!/bin/bash

set - e

swift build --static-swift-stdlib -c release
ARCH=$(uname -m)
OS="ubuntu24.04"
OUTPUT="wsm-${OS}-${ARCH}-static.tar.gz"
mkdir wsm
cp .build/release/wsm wsm/wsm
cp -r .build/release/wsm_wsm.resources wsm/wsm_wsm.resources
tar -czvf $OUTPUT wsm/
mv $OUTPUT ../