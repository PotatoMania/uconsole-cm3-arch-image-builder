#!/bin/bash

# These are general configs

# working directory
WORKING_DIR="/workspace/image-build"

# image file name
IMAGE_NAME="test-image.img"

# full image size, in MiB
IMAGE_SIZE=4096

# boot partition size, in MiB
BOOT_SIZE=300

# swapfile size, in MiB. swapfile is used so the partition can be flexible
# swapfile location is hardcoded in corresponding script
SWAP_SIZE=1024

# RootFS tar ball, ommit to use pacstrap
# or read from environment
# can be online resource
# currently only support for pacstrap and http source are implemented
#ROOTFS_ARCHIVE=http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz

# Pacstrap bootstrapping settings
PACSTRAP_PACMAN_CONFIG_FILE=resources/arch-stage0-pacman.conf
# For China mainland users
#PACSTRAP_PACMAN_CONFIG_FILE=resources/arch-stage0-cn-pacman.conf

# first privileged user's name and password
USER_NAME=ucon
USER_PASSWD=ucon

# mountpoint
IMAGE_MOUNT_POINT=mp

# pacstrap extra packages
# These are packages present in official archlinuxarm repository
PACSTRAP_EXTRA_PACKAGES=(
	base
	archlinuxarm-keyring
	raspberrypi-bootloader
	linux-firmware
	wireless-regdb
	mkinitcpio # install prior to kernel to avoid extra initramfs generation
	networkmanager
	vim
	sudo
)

# These are custom packages, located in pkgs
CUSTOM_PACKAGES=(
  # Wireless firmware, packaged
	"ap6256-firmware-0.1.20231120-1-any.pkg.tar.zst"
	# kernel at end, so initramfs only generated once
	"linux-uconsole-cm3-rpi64-6.1.58.r1.11535.64044d0961eb-1-aarch64.pkg.tar.zst"
)

######## don't change code below this line unless you understand the outcome ########
#####################################################################################

# check necessary variables
check_var_non_empty() {
	for v in "$@"
	do
		if [ -z "${!v}" ]
		then
			echo "Variable $v should not be empty! Export it or set it in envs.sh. Aborting."
			exit 1
		fi
	done
}

check_var_non_empty \
	WORKING_DIR IMAGE_NAME BOOT_SIZE

# prepare workspace folder
mkdir -p ${WORKING_DIR}

# concate to get image path
IMAGE_FILE=${WORKING_DIR%/}/${IMAGE_NAME}

# pad a little before first partition, MiB
PART_PAD_SIZE=${PART_PAD_SIZE:-16}

# limit minimum boot partition size to 300MiB
if ! test 300 -lt $BOOT_SIZE
then
	BOOT_SIZE=300
fi

# commands for parted
# using MBR to avoid tweaking hybrid MBR
PARTITION_COMMANDS=(
  "mklabel msdos"
	"mkpart primary fat32 ${PART_PAD_SIZE}MiB $((PART_PAD_SIZE+BOOT_SIZE))MiB"
	"set 1 boot on"
	"mkpart primary ext4 $((PART_PAD_SIZE+BOOT_SIZE))MiB 100%"
)
