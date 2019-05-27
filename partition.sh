#!/bin/bash
disk_size=`(blockdev --getsize64 /dev/sda)`
mem_total=`(cat /proc/meminfo | awk '/MemTotal/ {print $2}')`
echo $disk_size
echo $mem_total

disk=dev/sda

sfdisk $disk << EFO
, 512M, ef
, mem_totalB, 82
, , 85
EFO
