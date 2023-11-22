#!/bin/bash
# This script write fstab

source ./envs.sh
check_var_non_empty WORKING_DIR IMAGE_MOUNT_POINT

# abort on any error
set -e

_MP=${WORKING_DIR%/}/${IMAGE_MOUNT_POINT%/}

# override original one
# using UUID, but remove swaps
genfstab -U "${_MP}" \
    | sed -E '/./{H;$!d} ; x ; s:(\n)?#.*\n.*swap.*::g' \
    | sed -E "s:(/dev/sd[a-z])|(/dev/loop[0-9]+p):/dev/mmcblk0p:g" \
    > "${_MP}/etc/fstab"

# not using uuid, replace block pathes, remove swaps
# genfstab "${_MP}" \
#     | sed -E "s:(/dev/sd[a-z])|(/dev/loop[0-9]+p):/dev/mmcblk0p:g" \
#     | sed -E '/./{H;$!d} ; x ; s:(\n)?#.*\n.*swap.*::g' \
#     > "${_MP}/etc/fstab"

# add swapfile
if [ -f "${_MP}/swapfile" ]
then
    printf "# Swap\n/swapfile  none  swap  defaults  0 0\n" >> "${_MP}/etc/fstab"
fi
