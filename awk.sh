#!/bin/bash
bytes_to_gigabytes=1073741824
kilobytes_to_gigabytes=1048576

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

sfdisk --delete $disk

sfdisk $disk << EFO
, 512M, ef
, ${mem_total_mb}M, 82
, , 85
EFO
