#!/bin/bash
disk_size=`(blockdev --getsize64 /dev/sda)`
mem_total_kb=`(cat /proc/meminfo | awk '/MemTotal/ {print $2}')`
mem_total_mb=`(expr $mem_total_kb / 1000)`
echo $disk_size
echo $mem_total_mb

disk=/dev/sda

sfdisk $disk << EFO
, 512M, ef
, ${mem_total}M, 82
, , 85
EFO
