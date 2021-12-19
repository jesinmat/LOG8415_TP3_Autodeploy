#!/bin/bash
set -e

cd loadbalancer
./cleanup-1.sh

cd ../lambda
./3-cleanup.sh

cd ../loadbalancer
./cleanup-2.sh

#rm -r tmp/

echo "Cleanup done!"