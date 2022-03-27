#!/bin/bash

DRIVE="/dev/sda"
HOSTNAME="archvm"
USERNAME="vmuser"
PASSWORD="password"

start()
{
    echo "Setting drive partitions..."
    make_partition

    echo "Formatting and mounting filesystems..."
    format_and_mnt_fs

    echo "Installing linux system and other base packages..."
    install_base
}

make_partition()
{
    local dev = $1

    # Create partitions 
    parted -s "$dev" \
        mklabel msdos \
        mkpart primary fat32 1 300M \
        mkpart primary ext4 300M 100% \
        set 1 boot on
}

format_and_mnt_fs()
{
    echo ""
}

install_base()
{
    echo ""
}
