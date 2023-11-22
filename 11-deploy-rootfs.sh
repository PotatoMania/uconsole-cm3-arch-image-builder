#!/bin/bash
# This script download and extract the rootfs to target image

source ./envs.sh
check_var_non_empty WORKING_DIR IMAGE_MOUNT_POINT

_MP=${WORKING_DIR%/}/${IMAGE_MOUNT_POINT%/}
_PACSTRAP_EXTRA_PARAMS=()

if [ -n "$PACSTRAP_PACMAN_CONFIG_FILE" ]; then
    _PACSTRAP_EXTRA_PARAMS+="-C"
    _PACSTRAP_EXTRA_PARAMS+="$PACSTRAP_PACMAN_CONFIG_FILE"
fi

deploy_tarball() {
    case "${ROOTFS_ARCHIVE}" in
        http*)
            # download from http source
            ROOTFS_ARCHIVE_NAME=${ROOTFS_ARCHIVE##*/}
            if [ ! -f "${WORKING_DIR%/}/${ROOTFS_ARCHIVE_NAME}" ]
            then
                # file not found, download now
                set -e
                curl -qgb "" -fLC - --retry 3 --retry-delay 3 -o "${WORKING_DIR%/}/${ROOTFS_ARCHIVE_NAME}.partial" "${ROOTFS_ARCHIVE}"
                set +e
                mv "${WORKING_DIR%/}/${ROOTFS_ARCHIVE_NAME}.partial" "${WORKING_DIR%/}/${ROOTFS_ARCHIVE_NAME}"
            fi
            ;;
        *)
            echo "Support for ${ROOTFS_ARCHIVE} is not implemented!"
            exit 1
            ;;
    esac

    if [ 0 -lt "$(id -u)" ]; then
        BSDTAR="sudo bsdtar"
    else
        BSDTAR=bsdtar
    fi
    $BSDTAR -xpf "${WORKING_DIR%/}/${ROOTFS_ARCHIVE_NAME}" -C "${_MP}" 
}

# This should be executed in a AArch64 chroot
deploy_pacstrap() {
    # TODO: avoid generating the key
    pacstrap -KM "${_PACSTRAP_EXTRA_PARAMS[@]}" "${_MP}" base "${PACSTRAP_EXTRA_PACKAGES[@]}"
}

if [ -z "$ROOTFS_ARCHIVE" ]
then
    echo "Initialize rootfs using pacstrap"
    deploy_pacstrap
else
    echo "Using rootfs tarball provided"
    deploy_tarball
fi
