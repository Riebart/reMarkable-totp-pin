# reMarkable TOTP PIN

This will create a service that runs on the tablet that synchronizes the PIN to match a TOTP token generation app. It addresses a concern I had that the reMarkable's PIN is very easy to shoulder-surf, and I'm starting to accumulate a fair bit of content on mine that warrants some more diligent security.

## DISCLAIMER

![Here be dragons](http://ecx.images-amazon.com/images/I/51Hsvh0JutL.jpg)

This futzes with core reMarkable configuration files in indelicate ways. Any of a variety of things could go wrong, and if they do, you won't be able to unlock your device with a PIN.

If you use this, make sure to connect your tablet to WiFi every couple days for a few minutes to keep the clock from skewing too far from your authenticator device. If the clocks skew too far out, you'll find that your window for the code working will get smaller and smaller until your codes no longer work. _For comparison, my reMarkable loses about 1 second per day, so after a month would be completely out of sync with my phone given 30-second TOTP codes._

**I strongly recommend that all users that try this either memorize the developer SSH password, or set up public-key SSH authentication so that they can get in and fix things if this goes screws up.** I take no responsibility if you end up locked out because you didn't follow this step, but if you do feel free to create an issue or ping me on Reddit (u/Riebart) and I'll try to help.

## Files

- `deb_pkg_fetch.sh` Handles installing the necessary tools (`openssl`, `base32` and others)
  - Depends on `ar.sh` to mimic basic `ar` functionality to extract the `.deb`s
- `totp.sh` A script to generate TOTP tokens with openssl and bash [Source](https://github.com/Riebart/bash-totp)
- `totp_pin.sh` is the script that watches the wakeup count and framebuffer to only rotate the PIN when required
- `totp-pin.service`  is the systemd service file

## Installing

- Connect your reMarkable to WiFi and via USB to your computer
- Open a *nix terminal (macOS or Linux terminals work, or WSL on Windows)
- Clone this repo, and cd into the repo's root
- Run the `bash setup.sh` and put in your reMarkable SSH password when prompted.
- You will be shown a banner that indicates you should suspend (quick press the power button) your tablet
  - When you do this, you'll see a QR code in place of the usual suspend image. Scan this QR code with your authenticator app on your phone ([Google Authenticator](https://play.google.com/store/apps/details?id=com.google.android.apps.authenticator2&hl=en_us), [Microsoft Authenticator](https://play.google.com/store/apps/details?id=com.azure.authenticator&hl=en_us), or [Yubico Authenticator](https://play.google.com/store/apps/details?id=com.yubico.yubioath&hl=en_us)) before waking up your tablet.
  - Wake up your tablet, and your PINs will now be cycled to match your authenticator app! (Your original suspend image will be restored at this point, no worries!)

### Caveats

- The PIN is the first 4 digits of the 6 digit code
- You will likely need to enter a PIN twice to unlock the tablet. Your authenticator PIN will work on the second try
  - This is because the reMarkable software loads the configuration file when you wake up the tablet, but the new PIN wasn't written to the config file yet. When you get an incorrect pin, it reloads the config file, and picks up the new PIN.

## Uninstalling

If you need to undo these changes, this should work (run them via SSH on the tablet). They will reset your PIN to 1234.

```bash
systemctl stop totp-pin
systemctl disable totp-pin
rm -r /home/root/.config/totp/ \
      /usr/bin/openssl \
      /usr/bin/qrencode \
      /usr/bin/figlet-figlet \
      /usr/bin/base32 \
      /usr/bin/totp \
      /home/root/totp_pin.sh \
      /lib/systemd/system/totp-pin.service \
      /opt
systemctl daemon-reload
sed -i 's/^Password=[0-9]*/Password=1234/' /home/root/.config/remarkable/xochitl.conf
```

## TODO

- Better handling of cold-boot behaviour.
  - Currently, if you aren't really on the ball, or the rM's clock is a bit out of sync, you're going to have issues unlocking it after a cold boot.
  - You may need to suspend/wake it after a cold boot to get past the first PIN screen.
- Convert totp.sh to be a git submodule from https://github.com/riebart/bash-totp
  - Upstream needs a couple modifications to work on the reMarkable, and should support flexible digit counts
  - Ref: https://github.com/osdroid/noxquest_2fa/commit/cac285db93a272729e7d22b3cad61a9c668b3ab0
- Use 4-digit TOTP codes, not 6 (and only taking the first 4 digits).
