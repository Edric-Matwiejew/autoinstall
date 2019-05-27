#!/bin/bash
disk_size=`(blockdev --getsize64 /dev/sda)`
mem_total=`(cat /proc/meminfo | awk '/MemTotal/ {print $2}')`
echo $disk_size
echo $mem_total
