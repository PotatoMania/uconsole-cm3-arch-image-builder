#!/bin/bash
# This script creates a predefined privileged user

source ./envs.sh

_MP=${WORKING_DIR%/}/${IMAGE_MOUNT_POINT%/}
_MP_ABS=$(readlink -f "${_MP}")  # further ensure absolute path

NEW_USER_NAME=${NEW_USER_NAME:-ucon}
NEW_USER_PASSWORD=${NEW_USER_PASSWORD:-ucon}
NEW_USER_GROUPS=(adm wheel)

create_user() {
    useradd --root "$_MP_ABS" -m "${NEW_USER_NAME}"
    # weird, chpasswd --root doesn't work, complaining missing modules
    chroot "$_MP_ABS" sh -c "echo '$NEW_USER_NAME:$NEW_USER_PASSWORD' | chpasswd"
    for group in "${NEW_USER_GROUPS[@]}"; do
        usermod --root "$_MP_ABS" -aG "$group" "$NEW_USER_NAME"
    done
}

configure_sudo() {
    if [ ! -d "$_MP/etc/sudoers.d" ] ; then 
        mkdir -p -m750 "$_MP/etc/sudoers.d"
        chown root:root "$_MP/etc/sudoers.d"
    fi
    echo "%wheel ALL=(ALL:ALL) ALL" | install -o root -g root -Dm640 /dev/stdin "$_MP/etc/sudoers.d/allow-wheel"
}

if grep "1000:1000" "${_MP}/etc/passwd" > /dev/null
then
    echo "Found a default user with UID 1000, skipping creating new user."
    exit 0
fi

# create a new privileged user
create_user
configure_sudo
