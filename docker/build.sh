docker system prune -f

set -x

/usr/bin/time docker build . -t pt-apex:std -f Dockerfile.apex-std | tee build-pt-apex-std.txt
sync ; sync

sleep 30
/usr/bin/time docker build . -t pt-apex:opt -f Dockerfile.apex-opt | tee build-pt-apex-opt.txt
sync ; sync

sleep 30
sudo init 0
