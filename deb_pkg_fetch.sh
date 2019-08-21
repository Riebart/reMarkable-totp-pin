#!/bin/bash

set -e

function hashsponge {
    # Sponge stdin stored in a bash string armoured by xxd
    # Hash the content when the stream closes, and print the stream if the hash matches expected.
    target_hash="$1"
    if type xxd >/dev/null 2>&1
    then
        body=$(xxd)
        body_hash=$(echo "$body" | xxd -r | sha256sum -c <(echo "$target_hash  -"))
        hash_ok=$?
        if [ $hash_ok -eq 0 ]
        then
            echo "$body" | xxd -r
        else
            echo "hash mismatch: $target_hash v $body_hash" >&2
            exit 2
        fi
    fi
}

function deb_pkg_sha256 {
    wget -qO- "$1" | grep SHA256 | tr '<>\t' ' ' | tr -s ' ' | cut -d ' ' -f9
}

# We can pull from the Debian Stretch repos, but not buster.

# Get OpenSSL
echo "Getting OpenSSL and libssl/libcrypto" >&2
wget -qO- 'http://security.debian.org/debian-security/pool/updates/main/o/openssl/openssl_1.1.0k-1~deb9u1_armhf.deb' | \
    hashsponge ${1} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./usr/bin/openssl

# Get libcrypto and libssl
wget -qO- 'http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.0k-1~deb9u1_armhf.deb' | \
    hashsponge ${2} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./usr/lib/arm-linux-gnueabihf/libcrypto.so.1.1 \
        ./usr/lib/arm-linux-gnueabihf/libssl.so.1.1

# We only need base32 from here, but... y'know
echo "Getting base32" >&2
wget -qO- 'http://http.us.debian.org/debian/pool/main/c/coreutils/coreutils_8.26-3_armhf.deb' | \
    hashsponge ${3} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./usr/bin/base32

# We need a more modern libc and libpthread and others.
echo "Getting modern libc" >&2
wget -qO- 'http://http.us.debian.org/debian/pool/main/g/glibc/libc6_2.24-11+deb9u4_armhf.deb' | \
    hashsponge ${4} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./lib/arm-linux-gnueabihf/libc.so.6 \
        ./lib/arm-linux-gnueabihf/libc-2.24.so \
        ./lib/arm-linux-gnueabihf/libpthread.so.0 \
        ./lib/arm-linux-gnueabihf/libpthread-2.24.so \
        ./lib/arm-linux-gnueabihf/libdl.so.2 \
        ./lib/arm-linux-gnueabihf/libdl-2.24.so \
        ./lib/arm-linux-gnueabihf/ld-2.24.so \
        ./lib/ld-linux-armhf.so.3 \
        ./lib/arm-linux-gnueabihf/ld-linux-armhf.so.3

echo "Getting inotify tools and libraries" >&2
wget -qO- 'http://http.us.debian.org/debian/pool/main/i/inotify-tools/libinotifytools0_3.14-2_armhf.deb' | \
    hashsponge ${5} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./usr/lib/libinotifytools.so.0 \
        ./usr/lib/libinotifytools.so.0.4.1

wget -qO- 'http://http.us.debian.org/debian/pool/main/i/inotify-tools/inotify-tools_3.14-2_armhf.deb' | \
    hashsponge ${6} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./usr/bin/inotifywait \
        ./usr/bin/inotifywatch

echo "Getting qrencode and libpng/zlib libraries" >&2
wget -qO- 'http://http.us.debian.org/debian/pool/main/q/qrencode/qrencode_3.4.4-1+b2_armhf.deb' | \
    hashsponge ${7} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./usr/bin/qrencode

wget -qO- 'http://http.us.debian.org/debian/pool/main/q/qrencode/libqrencode3_3.4.4-1+b2_armhf.deb' | \
    hashsponge ${8} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./usr/lib/arm-linux-gnueabihf/libqrencode.so.3 \
        ./usr/lib/arm-linux-gnueabihf/libqrencode.so.3.4.4

wget -qO- 'http://security.debian.org/debian-security/pool/updates/main/libp/libpng1.6/libpng16-16_1.6.28-1+deb9u1_armhf.deb' | \
    hashsponge ${9} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./usr/lib/arm-linux-gnueabihf/libpng16.so.16 \
        ./usr/lib/arm-linux-gnueabihf/libpng16.so.16.28.0

wget -qO- 'http://http.us.debian.org/debian/pool/main/z/zlib/zlib1g_1.2.8.dfsg-5_armhf.deb' | \
    hashsponge ${10} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./lib/arm-linux-gnueabihf/libz.so.1 \
        ./lib/arm-linux-gnueabihf/libz.so.1.2.8

echo "Getting figlet" >&2
wget -qO- 'http://http.us.debian.org/debian/pool/main/f/figlet/figlet_2.2.5-2+b1_armhf.deb' | \
    hashsponge ${11} | \
    bash ar.sh data.tar.xz 2>/dev/null | \
    tar -xJf - \
        ./usr/bin/figlet-figlet \
        ./usr/share/figlet/standard.flf

echo '#!/bin/bash' "
LD_LIBRARY_PATH=\"`pwd`/usr/lib/arm-linux-gnueabihf/:`pwd`/lib/arm-linux-gnueabihf/:`pwd`/usr/lib\" `pwd`/usr/bin/openssl" '$@' > export/openssl

echo '#!/bin/bash' "
LD_LIBRARY_PATH=\"`pwd`/usr/lib/arm-linux-gnueabihf/:`pwd`/lib/arm-linux-gnueabihf/:`pwd`/usr/lib\" `pwd`/usr/bin/inotifywait" '$@' > export/inotifywait

echo '#!/bin/bash' "
LD_LIBRARY_PATH=\"`pwd`/usr/lib/arm-linux-gnueabihf/:`pwd`/lib/arm-linux-gnueabihf/:`pwd`/usr/lib\" `pwd`/usr/bin/inotifywatch" '$@' > export/inotifywatch

echo '#!/bin/bash' "
LD_LIBRARY_PATH=\"`pwd`/usr/lib/arm-linux-gnueabihf/:`pwd`/lib/arm-linux-gnueabihf/:`pwd`/usr/lib\" `pwd`/usr/bin/qrencode" '$@' > export/qrencode

echo '#!/bin/bash' "
LD_LIBRARY_PATH=\"`pwd`/usr/lib/arm-linux-gnueabihf/:`pwd`/lib/arm-linux-gnueabihf/:`pwd`/usr/lib\" `pwd`/usr/bin/figlet-figlet" '$@' > export/figlet-figlet

chmod +x export/*
