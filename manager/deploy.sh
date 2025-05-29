#!/bin/bash

set -e

swift build --static-swift-stdlib -c release

rm -rf /data/whooshing/.manager/web/bundle

mkdir -p /data/whooshing/.manager/web/bundle

cp pm2.config.json /data/whooshing/.manager/web/bundle/pm2.config.json

cp -r .build/x86_64-unknown-linux-gnu/release/App /data/whooshing/.manager/web/bundle/App