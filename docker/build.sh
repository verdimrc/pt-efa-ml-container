#!/bin/bash
#
docker system prune -f

set -x

# Disable color in docker logs
export NO_COLOR=1
export BUILDKIT_PROGRESS=plain

/usr/bin/time docker build . -t pt-apex:std -f Dockerfile.apex-std 2>&1 | tee build-pt-apex-std.txt
sync ; sync

sleep 30
/usr/bin/time docker build . -t pt-apex:opt -f Dockerfile.apex-opt 2>&1 | tee build-pt-apex-opt.txt
sync ; sync

sleep 30
sudo init 0
