#!/bin/bash
# This script unmount the partitions and free the loop device

source ./envs.sh
check_var_non_empty IMAGE_FILE

# compress using ZSTD
zstd "$IMAGE_FILE"
