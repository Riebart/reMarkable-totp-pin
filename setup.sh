#!/bin/bash

set -e

function deb_pkg_sha256 {
    wget -qO- "$1" | grep SHA256 | tr '<>\t' ' ' | tr -s ' ' | cut -d ' ' -f9
}

echo "Getting Debian Stretch armhf package hashes to pass to reMarkable"
package_hashes=""
for package in openssl libssl1.1 coreutils libc6 libinotifytools0 inotify-tools qrencode libqrencode3 libpng16-16 zlib1g figlet
do
    echo "Getting hash for $package"
    package_hashes="$package_hashes `deb_pkg_sha256 https://packages.debian.org/stretch/armhf/$package/download`"
done

tar -cf - rm-setup.sh deb_pkg_fetch.sh totp-pin.service totp_pin.sh ar.sh totp.sh | \
    ssh root@10.11.99.1 "cat - > /dev/shm/totp-pin.tar && cd /dev/shm && tar -xf totp-pin.tar rm-setup.sh && bash rm-setup.sh $package_hashes"
