#!/bin/bash
set -e

cd loadbalancer
./cleanup-1.sh

cd ../lambda
./3-cleanup.sh

echo "Waiting for network interfaces..."
sleep 120
cd ../loadbalancer
./cleanup-2.sh

cd ..
rm -r tmp/

echo "Cleanup done!"