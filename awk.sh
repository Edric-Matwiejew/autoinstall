#!/bin/bash
bytes_to_gigabytes=1073741824
kilobytes_to_gigabytes=1048576

wifi_dev=$(iw dev | awk '/Interface/ {print $2}')

ping -q -c 3 archlinux.org > /dev/null

if [ $? -eq 0 ]; then
	echo "Online using $wifi_dev."
else
	echo "Offline"
	exit
fi


timedatectl set-ntp true

timedatectl status

keysearch() {

echo

for (( ; ; ))
do
	read -p "Enter keyword to find your keyboard layout (enter ? to see full list): " layout

	if [ "$layout" == "?" ] 
	then
		ls /usr/share/kbd/keymaps/**/*.map.gz | less -m
	else
		break
	fi

done

LAYOUTS=()
LAYOUTS=($(ls /usr/share/kbd/keymaps/**/*$layout*.map.gz))
LAYOUTS+=("Search")

n=1

echo

for layout in ${LAYOUTS[@]}
	do
		echo "$((n++))) $(basename $layout)"
	done
echo

}

keysearch

for (( ; ; ))
do
	read -p "Choose keyboard layout: " input

	if (($input <= ${#LAYOUTS[@]} - 1 && $input >= 1));
	then

		layout=${LAYOUTS[$input]}
		 break

	elif (($input == ${#LAYOUTS[@]}));
	then

		keysearch

	fi
done

loadkeys $layout

echo
echo "Set keyboard layout to $(basename $layout)."
echo

if [ -d "/sys/firmware/efi/efivars" ]; then
	echo "UEFI mode enabled."
else
	echo "UEFI mode not enabled, exiting ArchLazy."
	exit
fi

list_disks() {
echo
echo "Detecting avaiable storage devices..."
echo 
n=1
sfdisk -l | awk -v count=1 ' 
BEGIN{printf "%-4s %-10s %-5s %-5s\n", "No.", "Disk", "Size", "Units"}
/Disk \/dev/ {
	gsub(":","",$2); 
	gsub(",","", $4); 
	printf "%-4s %-10s %-5s %-5s\n", count++")", $2, $3, $4
}'

echo
}

list_disks

OPTIONS+=("")
OPTIONS+=($(sfdisk -l | awk '/Disk \/dev/ {gsub(":","",$2); print $2}'))

PROMPT="Choose disk (enter 0 for details): " 

for (( ; ; ))
do
	read -p "$PROMPT" input

	if (("$input" == "0"));
	then
		echo
		fdisk -l
		read -rsp $'Press any key to continue...\n' -n1 key
		list_disks

	elif (($input <= ${#OPTIONS[@]} && $input >= 1));
	then
		 disk=${OPTIONS[$input]}
		 break
	fi
done

disk_size=`(blockdev --getsize64 $disk)`

mem_total_kb=`(cat /proc/meminfo | awk '/MemTotal/ {print $2}')`

mem_total_mb=`(expr $mem_total_kb / 1024)`
echo
echo "The following partition table will be written to ${disk}:"

boot_part=512
echo
printf "%-10s %-5s %-6s %-10s\n" "Device" "Size" "Units" "Type"
printf "%-10s %-5.1f %-6s %-10s\n" "${disk}1" "${boot_part}" "MiB" "EFI Boot"
echo $mem_total_kb $kilobytes_to_gigabytes | awk '{printf "%-10s %-5.1f %-6s %-10s\n", "'$disk'2", $1 / $2, "GiB", "Linux Swap"}'_
echo $disk_size $mem_total_kb $boot_part $bytes_to_gigabytes | awk '{printf "%-10s %-5.1f %-6s %-10s\n", "'$disk'3", ($1 - $2*1024 - $3*1024*1024) / $4, "GiB", "Linux Extended"}' 
echo

echo "###################################################################"
echo "WARNING: THIS WILL PERMANENTLY ERASE ALL DATA CURRENTLY ON ${disk}"
echo "###################################################################"

fdisk $disk << EOF
g
n
1

+512M
n
2

+${mem_total_kb}K
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

arch-chroot /mnt

#tzselect 

#hwclock --systohc


