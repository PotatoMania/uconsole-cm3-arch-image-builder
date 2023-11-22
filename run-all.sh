#!/bin/bash

./01-create-empty-image.sh
./02-create-partitions.sh
./10-load-format-mount-partitions.sh
./11-deploy-rootfs.sh
./11-prepare-swapfile.sh
./20-install-custom-packages.sh
./20-write-fstab.sh
./21-write-config-and-cmdline-txt.sh
./25-create-user.sh
./90-unmount-unload-partitions.sh
./95-compress-image-file.sh
./99-notice-after-installation.sh