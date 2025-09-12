# Image scripts

Here is a set of scripts to create a archlinux image for uConsole(CM3/CM4/CM4S) or whatever.

## How to use the scripts

- Install requirements.
    - For ArchLinux: `pacman -Sy --needed qemu-user-static qemu-user-static-binfmt arch-install-scripts parted dosfstools e2fsprogs`
- Review the settings in `settings.env`. Make changes if you want.
- Build the OS image by running `build-image.sh` with root privilege.

## Things to do after first boot

- Initialize pacman key database
    - `pacman-key --init && pacman-key --populate archlinux archlinuxarm`
- Resize the rootfs partition
    - Detail not covered here. You can use fdisk to resize the partition, and use `resize2fs` to actually expand the partition.
- Setup the internet connection
    1. Enable NetworkManager `systemd enable --now NetworkManager`
    1. Connect to WiFi `nmcli device wifi connect [SSID] password [password]`

## About default configuration

- Read `PACSTRAP_PACKAGES` in `settings.env` to learn included packages.
- Read `INSTALL_STATIC_FILES` in `settings.env` to learn preloaded config files.
- The new privileged user is `ucon`, with password `ucon`. *You'll change it right?*
