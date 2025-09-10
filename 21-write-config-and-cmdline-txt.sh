#!/bin/bash
# This script write config.txt and cmdline.txt for RPi
# will overwrite original values

source ./envs.sh
check_var_non_empty WORKING_DIR IMAGE_MOUNT_POINT

_MP=${WORKING_DIR%/}/${IMAGE_MOUNT_POINT%/}

cat << EOF > "${_MP}/boot/config.txt"
[all]
ignore_lcd=1
disable_fw_kms_setup=1
disable_audio_dither
pwm_sample_bits=20

# setup headphone detect pin
gpio=10=ip,np

# boot custom kernel
kernel=vmlinuz-linux-uconsole-rpi64
arm_64bit=1
initramfs initramfs-linux-uconsole-rpi64.img followkernel

dtoverlay=dwc2,dr_mode=host
dtoverlay=audremap,pins_12_13
dtparam=audio=on

[pi3]
dtoverlay=vc4-kms-v3d
dtoverlay=uconsole

[cm4]
arm_boost=1
max_framebuffers=2
dtoverlay=vc4-kms-v3d-pi4
dtoverlay=uconsole,cm4,hwi2c

[cm4s]
arm_boost=1
max_framebuffers=2
dtoverlay=vc4-kms-v3d-pi4
dtoverlay=uconsole,hwi2c

[all]
# whatever you need
EOF

cat << EOF > "${_MP}/boot/cmdline.txt"
root=/dev/mmcblk0p2 rootfstype=ext4 rw rootwait loglevel=3 cpufreq.default_governor=schedutil
EOF

# Enable NetworkManager and SSH during build
echo "Enabling NetworkManager and SSH..."
if chroot "${_MP}" systemctl enable NetworkManager; then
    echo "NetworkManager enabled successfully"
else
    echo "Warning: Failed to enable NetworkManager"
fi

if chroot "${_MP}" systemctl enable sshd; then
    echo "SSH enabled successfully"
else
    echo "Warning: Failed to enable SSH"
fi

# Create a simple keyring init script for first use
cat > "${_MP}/usr/local/bin/init-keyring.sh" << 'EOF'
#!/bin/bash
if [ ! -f /var/lib/keyring-initialized ]; then
    echo "Initializing package signing keys (this may take a few minutes)..."
    
    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ]; then
        echo "This script needs to run as root. Use: sudo init-keyring.sh"
        exit 1
    fi
    
    if pacman-key --init && pacman-key --populate archlinuxarm; then
        touch /var/lib/keyring-initialized
        echo "✓ Keyring initialized successfully!"
        echo "You can now install packages with pacman."
    else
        echo "✗ Failed to initialize keyring. Check your internet connection."
        exit 1
    fi
else
    echo "Keyring already initialized."
fi
EOF
chmod +x "${_MP}/usr/local/bin/init-keyring.sh"

# Add helpful message to MOTD
cat >> "${_MP}/etc/motd" << 'EOF'

Welcome to uConsole Arch Linux!

First-time setup:
1. Connect to WiFi: nmcli dev wifi connect "SSID" password "PASSWORD"
   Or use the text UI: nmtui
2. Initialize package keyring: sudo init-keyring.sh
3. Update system: sudo pacman -Syu

For help: https://wiki.archlinux.org/
EOF