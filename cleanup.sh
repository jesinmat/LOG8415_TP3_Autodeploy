#!/bin/bash
set -e

cd loadbalancer
./cleanup-1.sh

cd ../lambda
./3-cleanup.sh

sleep 50
cd ../loadbalancer
./cleanup-2.sh

cd ..
rm -r tmp/

echo "Cleanup done!"