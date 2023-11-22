# Image scripts

Here is a set of scripts to create a archlinux image for uConsole(CM3) or whatever.

## How to use the scripts

`envs.sh` is the global config file. Edit the envs as you wish, and run the scripts in ascending order.
Or, for convenience, run `run-all.sh` once.

No script needs user interaction. But be careful, scripts require superuser privilege.

To install requirements on ArchLinux:

```bash
pacman -Sy qemu-user-static qemu-user-static-binfmt arch-install-scripts
```

## About default configuration

Read the `env.sh` first. It's not long.

The default configuration is for CM3(and possibly CM4) with the necessary additions to enable the wireless module.

The default privileged user's name and password are both `ucon`.

It may be necessary to setup locales, package repository mirrors, etc. after flashing the image.

The network can be managed via `nmcli`, given Network Manager enabled via `systemctl enable --now NetworkManager`.

`vim` is installed as a preloaded text editor.

The partition must be resized to utilize all space on uSD card.
