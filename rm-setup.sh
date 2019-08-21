#!/bin/bash

set -e

echo "Fetching a bunch of Debian Stretch armhf packages (openssl, base32, qrencode)"
mkdir -p /opt/debian/export
cd /opt/debian
tar -xf /dev/shm/totp-pin.tar ar.sh deb_pkg_fetch.sh
bash deb_pkg_fetch.sh $@ 2>&1

echo "Symlinking Debian binaries into /usr/bin"
rm -f /usr/bin/qrencode \
      /usr/bin/figlet-figlet \
      /usr/bin/openssl \
      /usr/bin/base32

ln -s /opt/debian/export/qrencode \
      /opt/debian/export/figlet-figlet \
      /opt/debian/export/openssl \
      /opt/debian/usr/bin/base32 \
      /usr/bin/

echo "Installing the TOTP code generation script"
cd /usr/bin
tar -xf /dev/shm/totp-pin.tar totp.sh
mv totp.sh totp
chmod +x totp

echo "Installing the systemd service"
cd /home/root
tar -xf /dev/shm/totp-pin.tar totp_pin.sh
cd /lib/systemd/system/
tar -xf /dev/shm/totp-pin.tar totp-pin.service

echo "Generating secret key material"
mkdir -p /home/root/.config/totp/
dd if=/dev/urandom bs=1 count=32 2>/dev/null | base32 > /home/root/.config/totp/secret.b32
echo 30 > /home/root/.config/totp/duration

echo "Generating authentication QR Code and setting as suspend screen."
echo "otpauth://totp/reMarkable:reMarkable?secret=`cat /home/root/.config/totp/secret.b32`&issuer=reMarkable" | \
    qrencode -s 8 -l L -m 99 -o out.png
mv /usr/share/remarkable/suspended.png /usr/share/remarkable/suspended.png.bak
mv out.png /usr/share/remarkable/suspended.png

figlet-figlet -f /opt/debian/usr/share/figlet/standard.flf \
    Put your reMarkable to sleep and scan the QR code with your smartphone app before waking it back up.

cd /tmp
(
    ts=`date -u +%s` && \
    while [ `date -u +%s` -lt $[ts+3] ]; \
        do ts=$(date -u +%s); sleep 1; done && \
    rm /usr/share/remarkable/suspended.png && \
    mv /usr/share/remarkable/suspended.png.bak /usr/share/remarkable/suspended.png && \
    systemctl daemon-reload && \
    systemctl enable totp-pin.service && \
    systemctl start totp-pin.service
) > /dev/null 2>/dev/null &
