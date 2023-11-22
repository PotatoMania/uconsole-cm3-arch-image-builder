#!/bin/bash
# This script write swapfile on demand

source ./envs.sh
check_var_non_empty WORKING_DIR IMAGE_MOUNT_POINT

if ! test 0 -lt "$SWAP_SIZE"
then
    echo "Find no valid SWAP_SIZE, skipping swapfile creation"
    exit 0
fi

_SWAPFILE=${WORKING_DIR%/}/${IMAGE_MOUNT_POINT%/}/swapfile

echo "Creating ${_SWAPFILE}, size ${SWAP_SIZE} MiB"
dd if=/dev/zero of=${_SWAPFILE} bs=1M count=${SWAP_SIZE}
