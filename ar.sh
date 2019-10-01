#!/bin/bash

set -e

# Test reading a bunch of stuff from stdin

read -n8 global_header
bytes_in=8

while [ "$global_header" == '!<arch>' ]
do
    if [ $[bytes_in%2] -eq 1 ]
    then
        dd bs=1 count=1 >/dev/null 2>&1
    fi

    file_name=$(dd bs=1 count=16 2>/dev/null | tr -d '\n ')
    if [ "$file_name" == "" ]
    then
        break
    fi
    read -n12 mod_ts
    read -n6 owner
    read -n6 group
    read -n8 mode
    read -n10 file_size
    echo "$file_name = $file_size bytes" >&2
    read -n2 end
    bytes_in=$[bytes_in+60]
    if [ $# -gt 0 ]
    then
        for inner_name in $@
        do
            if [ "$file_name" == "$inner_name" ]
            then
                dd bs=1048576 count=$[1048576*(file_size/1048576)] 2>/dev/null
                dd bs=$[file_size-1048576*(file_size/1048576)] count=1 2>/dev/null
                exit
            fi
        done
    fi

    # If we haven't consumed the file body to print it, then skip it
    dd bs=1 count=$file_size 2>/dev/null > /dev/null
    bytes_in=$[bytes_in+file_size]
done
