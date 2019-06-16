#!/bin/bash

timedatectl set-ntp true
timedatectl status

disk=/dev/sda
mem_size=1

fdisk $disk << EOF
g
n
1

+512M
n
2

+${mem_size}G
n
3


t
1
1
t
2
19
w
EOF

partprobe $disk

mkfs.fat -F32 ${disk}1
mkfs.ext4 -F ${disk}3
mkswap -f ${disk}2
swapon ${disk}2

mkdir /mnt

mount ${disk}3 /mnt

mkdir /mnt/efi

mount ${disk}1 /mnt/efi

pacstrap /mnt base base-devel

genfstab -U /mnt >> /mnt/etc/fstab

hostname=t1ger
password=bright

arch-chroot /mnt << rootdo
ln -sf /usr/share/zoneinfo/Australia/Perth /etc/localtime

hwclock --systohc --utc

echo "en_AU.UTF-8 UTF-8" >> selected_locales

while read line
do
	sed -i "s/\#\$line/\$line/g" /etc/locale.gen
done < selected_locales

locale-gen
echo "LANG=en_AU.UTF-8" > /etc/locale.conf

echo $hostname >> /etc/hostname

# assuming IP address us not static other the user should be able to replace the IP address below with their own.

echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> etc/hosts
echo "127.0.1.1 ${hostname}.localdomain $hostname" >> /etc/hosts

passwd << EOF
$password
$password
EOF

#installing bootloader
pacman --noconfirm -S grub
pacman --noconfirm -Syu efibootmgr
grub-install --efi-directory=efi
grub-mkconfig -o /boot/grub/grub.cfg

#pacman -Syu

systemctl enable dhcpcd

useradd -m -G wheel edric
passwd edric << EOF
dogood
dogood
EOF

sed -i 's/# %wheel ALL=(ALL) ALL/ %wheel ALL=(ALL) ALL/' /etc/sudoers

exit

rootdo

#reboot

