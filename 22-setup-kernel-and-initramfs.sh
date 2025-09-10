#!/bin/bash
# This script sets up kernel files and generates initramfs

source ./envs.sh
check_var_non_empty WORKING_DIR IMAGE_MOUNT_POINT

_MP=${WORKING_DIR%/}/${IMAGE_MOUNT_POINT%/}
_MP_ABS=$(readlink -f "${_MP}")

echo "Setting up kernel and initramfs..."

# Create the missing mkinitcpio preset
cat > "${_MP}/etc/mkinitcpio.d/linux-uconsole-rpi64.preset" << 'EOF'
# mkinitcpio preset file for the linux-uconsole-rpi64 package

ALL_config="/etc/mkinitcpio.conf"
ALL_kver="/boot/vmlinuz-linux-uconsole-rpi64"

PRESETS=('default')

default_image="/boot/initramfs-linux-uconsole-rpi64.img"
EOF

# Find the kernel version
KERNEL_VERSION=$(ls "${_MP}/usr/lib/modules/" | head -1)
echo "Found kernel version: $KERNEL_VERSION"

# Copy kernel from modules directory to /boot in rootfs
if [ -f "${_MP}/usr/lib/modules/${KERNEL_VERSION}/vmlinuz" ]; then
    cp "${_MP}/usr/lib/modules/${KERNEL_VERSION}/vmlinuz" "${_MP}/boot/vmlinuz-linux-uconsole-rpi64"
    echo "Copied kernel to rootfs /boot"
else
    echo "ERROR: Kernel file not found"
    exit 1
fi

# Set up proper chroot environment and generate initramfs
echo "Generating initramfs..."

# Mount necessary filesystems for chroot
mount --bind /dev "${_MP}/dev"
mount --bind /proc "${_MP}/proc" 
mount --bind /sys "${_MP}/sys"

# Generate initramfs in chroot
chroot "${_MP}" /bin/bash -c "
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    mkinitcpio -k ${KERNEL_VERSION} -g /boot/initramfs-linux-uconsole-rpi64.img
"

# Clean up bind mounts
umount "${_MP}/sys" || true
umount "${_MP}/proc" || true  
umount "${_MP}/dev" || true

# Verify initramfs was created
if [ ! -f "${_MP}/boot/initramfs-linux-uconsole-rpi64.img" ]; then
    echo "ERROR: initramfs generation failed"
    exit 1
fi

echo "Kernel and initramfs setup completed successfully"
echo "Kernel: $(ls -lh ${_MP}/boot/vmlinuz-linux-uconsole-rpi64)"
echo "Initramfs: $(ls -lh ${_MP}/boot/initramfs-linux-uconsole-rpi64.img)"