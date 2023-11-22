#!/bin/bash
# This script install custom packages(include kernel and firmware packages)
# to the rootfs. The packages are located in `pkgs`

source ./envs.sh
check_var_non_empty WORKING_DIR IMAGE_MOUNT_POINT

_MP=${WORKING_DIR%/}/${IMAGE_MOUNT_POINT%/}

mkdir -p "${_MP}/pkgs"

for pkg in "${CUSTOM_PACKAGES[@]}"; do
    cp "pkgs/$pkg" "${_MP}/pkgs/"
    arch-chroot "${_MP}" pacman -U --noconfirm "/pkgs/$pkg"
    rm "${_MP}/pkgs/$pkg"
done

rmdir "${_MP}/pkgs"
