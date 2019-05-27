#!/bin/bash

list_disks() {
echo
echo "Detecting avaiable storage devices..."
echo 

sfdisk -l | awk ' 

BEGIN{printf "%-4s %-10s %-5s %-5s\n", "No.", "Device", "Size", "Units"}

/Disk \/dev/ {
	gsub(":","",$2); 
	gsub(",","", $4); 
	printf "%-4s %-10s %-5s %-5s\n", NR")", $2, $3, $4
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

disk_size=`(blockdev --getsize64 /dev/sda)`
mem_total_kb=`(cat /proc/meminfo | awk '/MemTotal/ {print $2}')`

mem_total_mb=`(expr $mem_total_kb / 1000)`

sfdisk --delete $disk

sfdisk $disk << EFO
, 512M, ef
, ${mem_total_mb}M, 82
, , 85
EFO
