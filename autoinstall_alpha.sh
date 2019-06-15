#!/bin/bash

timedatectl set-ntp true
timedatectl status

sda="/dev/sda"
mem_size=16

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

pacstrap /mnt base

genfstab -U /mnt >> /mnt/etc/fstab

timezone=$(tzselect)

arch-chroot /mnt << "rootdo"
ln -sf /usr/share/zoneinfo/${timezone} /etc/localtime
hwclock --systohc
source locale_search.sh
locale_selection

while read line
do
	echo \#{$line}
	sed -i "s/\#$line/$line/g" /etc/locale.gen
done < selected_locales

locale-gen

# SET LANGUAGE


read -p "Enter your hostmane: " hostname
echo $hostname >> /etc/hostname

# assuming IP address us not static other the user should be able to replace the IP address below with their own.

echo "127.0.0.1 localhost" >> /etc/hosts
echo "::1 localhost" >> etc/hosts
echo "127.0.1.1 "${hostname}".localdomain "$hostmane"" >> /etc/hosts

#network config here

read -P "Enter you password " password

passwd $password

#installing bootloader
pacman -S grub
grub-install /dev/"$disk"
grub-mkconfig -o /boot/grub/grub.cfg

pacman -Syu

exit

rootdo

reboot

