# uConsole Arch Linux Image Builder

A set of scripts to create a ready-to-use Arch Linux ARM image for the Clockwork Pi uConsole (CM3/CM4/CM4S).

## Features

- **Universal compatibility**: Works with CM3, CM4, and CM4S modules
- **Complete WiFi support**: Includes multiple WiFi management tools (NetworkManager, iwd, wpa_supplicant)
- **Pre-configured display**: Display settings optimized for uConsole screen
- **Automatic first-boot setup**: NetworkManager and SSH enabled by default
- **Comprehensive package set**: Includes essential networking, development, and troubleshooting tools

## Requirements

### Build System
- Arch Linux host system (or compatible ARM build environment)
- Root/sudo access
- At least 8GB free disk space
- Internet connection for package downloads

### Install build dependencies:
```bash
sudo pacman -Sy --needed qemu-user-static qemu-user-static-binfmt arch-install-scripts parted dosfstools e2fsprogs
```

### Target Hardware  
- uConsole with CM3, CM4, or CM4S module
- MicroSD card (8GB minimum, 32GB+ recommended)

## Quick Start

1. **Clone and configure**:
   ```bash
   git clone https://github.com/PotatoMania/uconsole-cm3-arch-image-builder.git
   cd uconsole-cm3-arch-image-builder
   # Edit envs.sh to customize your build (optional)
   ```

2. **Build the image**:
   ```bash
   sudo ./run-all.sh
   ```

3. **Flash to SD card**:
   ```bash
   # Find your SD card device
   lsblk
   
   # Flash the image (replace sdX with your actual device)
   sudo dd if=/workspace/image-build/uconsole_arch.img of=/dev/sdX bs=4M status=progress
   sudo sync
   ```

4. **Boot and setup**:
   - Insert SD card into uConsole and power on
   - Connect to WiFi: `nmcli dev wifi connect "YourSSID" password "YourPassword"`
   - Initialize package signing: `sudo init-keyring.sh`
   - Update system: `sudo pacman -Syu`

## Configuration

### Default Settings
- **User account**: `ucon` / `ucon` (configured in `envs.sh`)
- **Image size**: ~4GB (configurable in `envs.sh`)
- **Swap**: 1GB swapfile
- **Editors**: vim and nano pre-installed
- **Services**: NetworkManager and SSH enabled by default

### Customization
Edit `envs.sh` before building to customize:
- Image size and partitioning
- User credentials
- Package selection
- Build location

## What's Included

### System Packages
- Base Arch Linux ARM system
- Custom uConsole kernel with display drivers
- WiFi firmware and regulatory database
- Essential system utilities

### Networking
- NetworkManager (primary)
- iwd (Intel wireless daemon)
- wpa_supplicant (traditional WiFi)
- dhcpcd (DHCP client)
- SSH server (enabled by default)

### Development & Troubleshooting
- vim, nano (text editors)
- htop (process monitor)
- wireless tools (iw, iwconfig, etc.)
- network utilities (ping, wget, curl)
- hardware detection tools (lshw, lsusb, lspci)

## Post-Installation

### First Boot
The system automatically:
- Starts NetworkManager for WiFi connectivity
- Enables SSH for remote access
- Displays helpful setup instructions

### Initial Setup
1. **Connect to WiFi**:
   ```bash
   # Command line
   nmcli dev wifi connect "YourSSID" password "YourPassword"
   
   # Or use text UI
   nmtui
   ```

2. **Initialize package manager**:
   ```bash
   sudo init-keyring.sh
   ```

3. **Update system**:
   ```bash
   sudo pacman -Syu
   ```

4. **Optional: Expand filesystem** (if needed):
   ```bash
   sudo resize2fs /dev/mmcblk0p2
   ```

### WiFi Troubleshooting
If WiFi doesn't work:
```bash
# Check WiFi interface
ip link show

# Scan for networks
nmcli dev wifi list

# Check driver status
dmesg | grep -i wifi

# Manual interface up
sudo ip link set wlan0 up
```

## Verification (Optional but Recommended)

Verify your flash was successful:
```bash
# Compare checksums of first 1GB
sudo dd if=/dev/sdX bs=4M count=256 | md5sum
sudo dd if=/workspace/image-build/uconsole_arch.img bs=4M count=256 | md5sum
# These should match
```

## Build Process Details

The build process runs these steps automatically:
1. Create empty disk image
2. Partition the image (boot + root)
3. Format and mount partitions  
4. Install base system with pacstrap
5. Install custom kernel and WiFi firmware
6. Generate initramfs and copy kernel files
7. Configure boot settings and services
8. Create user account
9. Compress final image

## Troubleshooting

### Build Issues
- **Permission denied**: Ensure you're running with `sudo`
- **Package download fails**: Check internet connection and mirrors
- **Out of space**: Increase `IMAGE_SIZE` in `envs.sh`

### Boot Issues  
- **Black screen**: Check SD card connection and power
- **Kernel panic**: Verify image was flashed completely
- **No WiFi**: Run `sudo init-keyring.sh` and update system

### Network Issues
- **Can't connect to WiFi**: Try `nmtui` for interactive setup
- **No internet after WiFi connects**: Check DNS with `nslookup google.com`