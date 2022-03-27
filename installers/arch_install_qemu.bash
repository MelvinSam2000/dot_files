#!/bin/bash

DRIVE="/dev/sda"
USERNAME="vmuser"
ROOTPASSWORD="password"
PASSWORD="password"

stage1_setup()
{
    echo ">>> Starting installation..."
    timedatectl set-ntp true

    echo ">>> Setting drive partitions..."
    make_partition $DRIVE

    echo ">>> Mounting filesystems..."
    format_and_mnt_fs $DRIVE

    echo ">>> Installing linux system and other base packages..."
    install_base

    echo ">>> Chrooting into installed system..."
    do_archchroot
}

stage2_setup()
{
    echo ">>> Config locales and timezone"
    locale_timezone_config

    echo ">>> Configuring GRUB..."
    setup_grub

    echo ">>> Configuring NetworkManager"
    setup_network_manager

    echo ">>> Setting root password..."
    set_password "root" $ROOTPASSWORD

    echo ">>> Create sudo user"
    set_sudo_user $USERNAME $PASSWORD
}

make_partition()
{
    local dev=$1

    # Create partitions 
    parted -s "$dev" \
        mklabel msdos \
        mkpart primary fat32 1 300M \
        mkpart primary ext4 300M 100% \
        set 1 boot on
}

format_and_mnt_fs()
{
    local dev=$1 
    local boot="${dev}1"
    local rootfs="${dev}2"

    # Format filesystems
    mkfs.fat -F 32 "${boot}"
    mkfs.ext4 "${rootfs}"

    # Mount filesystems
    mount "${rootfs}" /mnt
    mkdir /mnt/boot
    mount "${boot}" /mnt/boot
}

install_base()
{
    # Install packages to rootfs
    pacstrap /mnt base base-devel linux linux-firmware vim openssh
    
    # genfstab
    genfstab -U /mnt >> /mnt/etc/fstab
}

do_archchroot()
{
    # Copy and pass this script to continue execution
    cp $0 /mnt/installer.sh
    arch-chroot /mnt ./installer.sh stage2
}

locale_timezone_config()
{
    # Set timezone
    local TIMEZONE_PWD="/usr/share/zoneinfo/America/Toronto"
    ln -sf ${TIMEZONE_PWD} /etc/localtime

    # HW clock config
    hwclock --systohc

    # Locale config
    vim -c "%s/#en_US.UTF-8/en_US.UTF-8" -c ":wq" /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" >> /etc/locale.conf
}

setup_grub()
{
    pacman -Sy --noconfirm grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
}

setup_network_manager()
{
    pacman -Sy --noconfirm networkmanager 
    systemctl enable NetworkManager
}

set_sudo_user()
{
    local user=$1
    local password=$2
    useradd -m -G wheel "$user"
    vim -c "%s/# %wheel/%wheel" -c ":wq!" /etc/sudoers
    set_password "$user" "$password"
}

set_password() 
{
    local user="$1"
    local password="$2"
    echo -en "$password\n$password" | passwd "$user"
}

if [ "$1" == "stage2" ]
then
    stage2_setup
else
    stage1_setup
fi

