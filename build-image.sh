#!/usr/bin/env bash

# quit on error
set -e

###############################################################
# Preparation 
###############################################################

source shlib/misc.lib
source shlib/image-ops.lib

if ! check_is_root; then
    printf "This tool requires root privilege!\n"
    exit 1
fi

error_handler() {
    printf "Got error, cleaning up...\n"

	if [[ $(findmnt -M "${WORKING_DIR}/mount_point") ]]; then
		umount -R "${WORKING_DIR}/mount_point" || :
		losetup -d "${_LOOP_DEVICE}"
	fi
	if [ -f "${_IMAGE_FILE_PATH}" ]; then
		printf "You might want to delete %s manually.\n" "${_IMAGE_FILE_PATH}"
		printf "That file will NOT be overwritten if exists.\n"
	fi
	exit
}
trap error_handler ERR EXIT

BUILDER_CONFIG_FILE=$1
BUILDER_CONFIG_FILE=${BUILDER_CONFIG_FILE:-settings.env}
[ -f "$BUILDER_CONFIG_FILE" ] && source "$BUILDER_CONFIG_FILE" || {
    printf "Settings(%s) load failed! Exiting!\n" "$BUILDER_CONFIG_FILE"
    exit 1
}

mkdir -p "${WORKING_DIR}"
mkdir -p "${WORKING_DIR}/mount_point"

_IMAGE_FILE_PATH="${WORKING_DIR}/${IMAGE_NAME}"
_MOUNT_POINT=$(readlink -e "${WORKING_DIR}/mount_point")
_PACSTRAP_EXTRA_PARAMS=()

# check if a custom pacman config is provided
# otherwise pacman will use host system's config
if [ -n "$PACSTRAP_PACMAN_CONFIG" ]; then
    _PACSTRAP_EXTRA_PARAMS+=("-C")
    _PACSTRAP_EXTRA_PARAMS+=("$PACSTRAP_PACMAN_CONFIG")
fi

###############################################################
# Build OS image - Step 1 - Create partitions
###############################################################

# create empty image
create_image "${_IMAGE_FILE_PATH}" "${IMAGE_SIZE}"

# write partition table
initialize_partition_table_mbr "${_IMAGE_FILE_PATH}" "${MBR_PARTITION_SETUP[@]}"

# make image a loop device
_LOOP_DEVICE=$(losetup -f -P --show "${_IMAGE_FILE_PATH}")

# sometimes the partition table is not loaded(we're fast XD)
partprobe "${_LOOP_DEVICE}"

# format partitions
format_partitions "${_LOOP_DEVICE}" "${MBR_PARTITION_SETUP[@]}"

# mount the partition
mount_partitions "${_LOOP_DEVICE}" "${_MOUNT_POINT}" "${MBR_PARTITION_SETUP[@]}"

###############################################################
# Build OS image - Step 2 - Prepare rootfs
###############################################################

# bootstrap rootfs
pacstrap -G -M "${_PACSTRAP_EXTRA_PARAMS[@]}" "${_MOUNT_POINT}" base "${PACSTRAP_PACKAGES[@]}"

# prepare swap file
if [ "$SWAP_SIZE" -gt 0 ]; then
    dd if=/dev/zero of="${_MOUNT_POINT}/swapfile" bs=1M count=${SWAP_SIZE}
    chmod 0600 "${_MOUNT_POINT}/swapfile"
    mkswap "${_MOUNT_POINT}/swapfile"
fi

# copy resources, do this BEFORE installing offline packages
for entry in "${INSTALL_STATIC_FILES[@]}"; do
    source_file=$(cut -d':' -f1 <<< "${entry}")
    dest_location=$(cut -d':' -f2 <<< "${entry}")
    file_mode=$(cut -d':' -f3 <<< "${entry}")

    if [ "$file_mode" = "link" ]; then
        ln -sfT "${source_file}" "${_MOUNT_POINT}/${dest_location}"
        continue
    fi

    [ -n "$file_mode" ] || file_mode=644

    install -Dm"${file_mode}" "${source_file}" "${_MOUNT_POINT}/${dest_location}"
done

# install offline packages
if [ 0 -lt "${#INSTALL_EXTRA_PACKAGES[@]}" ]; then
    pacstrap -G -M -U "${_PACSTRAP_EXTRA_PARAMS[@]}" "${_MOUNT_POINT}" "${INSTALL_EXTRA_PACKAGES[@]}"
fi

# write fstab
# remove swap related lines, then rename all loop devices to mmcblk device
genfstab -U "${_MOUNT_POINT}" \
    | sed -E '/./{H;$!d} ; x ; s:(\n)?#.*\n.*swap.*::g' \
    | sed -E "s:(/dev/sd[a-z])|(/dev/loop[0-9]+p):/dev/mmcblk0p:g" \
    > "${_MOUNT_POINT}/etc/fstab"

if [ -f "${_MOUNT_POINT}/swapfile" ]; then
    printf "# Swap\n/swapfile  none  swap  defaults  0 0\n" >> "${_MOUNT_POINT}/etc/fstab"
fi

###############################################################
# Build image - Step 3 - Bootloader config
###############################################################

# write u-boot or other bootloader config
# do this on the loop device so the image file is not truncated
# otherwise extra params for dd are required
if [ -f "${UBOOT_BINARY}" ]; then
    printf "Installing U-Boot\n"
    check_var_non_empty UBOOT_ARCH UBOOT_OFFSET BOOT_SCRIPT_TEMPLATE BOOT_ENV_TEMPLATE

    dd if="${UBOOT_BINARY}" of="${_LOOP_DEVICE}" bs=512 seek=${UBOOT_OFFSET}

    # write boot scripts
    # the boot.cmd only needs a compilation
    # the variables in bootEnv.txt need some substitutions
    cp "${BOOT_SCRIPT_TEMPLATE}" "${_MOUNT_POINT}/boot/boot.cmd"
    mkimage -C none -A "${UBOOT_ARCH}" -T script -d "${_MOUNT_POINT}/boot/boot.cmd" "${_MOUNT_POINT}/boot/boot.scr"
    # get UUID for substitution
    _MOUNT_POINT_UUID=$(findmnt -Ufnro UUID -M "${_MOUNT_POINT}")
    _sed_subst="
    s|^rootdev=.*|rootdev=UUID=${_MOUNT_POINT_UUID}|g
    "
    sed "${_sed_subst}" "${BOOT_ENV_TEMPLATE}" | install -Dm644 /dev/stdin "${_MOUNT_POINT}/boot/bootEnv.txt"
    # some fixup
    if ! grep "^rootdev" "${_MOUNT_POINT}/boot/bootEnv.txt" > /dev/null; then
        printf "rootdev=UUID=%s\n" ${_MOUNT_POINT_UUID} >> "${_MOUNT_POINT}/boot/bootEnv.txt"
    fi
fi

###############################################################
# Post actions
###############################################################

# create initial privileged user
# NOTE: _MOUNT_POINT must be absolute path
if [ -n "$NEW_PRIV_USER" ]; then
    printf "Adding new privileged user: %s\n" "$NEW_PRIV_USER"

    useradd --root "${_MOUNT_POINT}" -m "${NEW_PRIV_USER}"
    chroot "${_MOUNT_POINT}" sh -c "echo '$NEW_PRIV_USER:$NEW_PRIV_USER_PASS' | chpasswd"
    usermod --root "${_MOUNT_POINT}" -aG "wheel" "$NEW_PRIV_USER"
    for group in "${NEW_PRIV_USER_GROUPS[@]}"; do
        usermod --root "${_MOUNT_POINT}" -aG "$group" "$NEW_PRIV_USER"
    done
    # write sudoers config
    if [ ! -d "${_MOUNT_POINT}/etc/sudoers.d" ] ; then 
        mkdir -p -m750 "${_MOUNT_POINT}/etc/sudoers.d"
        chown root:root "${_MOUNT_POINT}/etc/sudoers.d"
    fi
    echo "%wheel ALL=(ALL:ALL) ALL" | install -o root -g root -Dm640 /dev/stdin "${_MOUNT_POINT}/etc/sudoers.d/allow-users-in-wheel"
fi

###############################################################
# cleanup 
###############################################################

# remove exit trap
trap - EXIT

# umount and unload
umount -R "${_MOUNT_POINT}"
losetup -d "${_LOOP_DEVICE}"

printf "Done! The OS image is %s\n" "$WORKING_DIR/$IMAGE_NAME"

exit 0
