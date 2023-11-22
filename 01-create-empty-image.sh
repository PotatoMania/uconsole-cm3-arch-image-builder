#!/bin/bash
# This script simply create an empty image file to write

source ./envs.sh
check_var_non_empty IMAGE_FILE IMAGE_SIZE

# create an empty image, sparse file if fs support that
# dd if=/dev/zero of=${_IMAGE} bs=1M seek=${IMAGE_SIZE} count=0

# write a solid image file filled with zero
dd if=/dev/zero of=${IMAGE_FILE} bs=1M count=${IMAGE_SIZE}
