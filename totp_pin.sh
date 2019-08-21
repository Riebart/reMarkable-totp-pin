#!/bin/bash

function totp_rm_config {
    # Use the secret and duration stored in the files to calculate the token.
    secret=$(cat ~/.config/totp/secret.b32)
    duration=$(cat ~/.config/totp/duration)
    code=$(totp "$secret" "Google" "$duration" | dd bs=1 count=4 2>/dev/null)

    # Check to see if the token is in the rM config already
    if /bin/grep "^Password=$code" ~/.config/remarkable/xochitl.conf >/dev/null
    then
        :
    else
        echo "`date +%FT%T -u` TOTP token rotation" >&2
        sed -i "s/^Password=[0-9]*/Password=$code/" ~/.config/remarkable/xochitl.conf
    fi
}

function is_pin_screen_thorough {
    delta_pos=$(cmp /dev/zero /dev/fb0 | cut -d' ' -f5 | tr -dc '0-9')
    if [ $delta_pos -gt 1000000 ]
    then
        return 0
    else
        return 1
    fi
}

function is_pin_screen_mid {
    cmp \
        <(dd if=/dev/zero bs=10000 count=1 2>/dev/null) \
        <(dd if=/dev/fb0 bs=10000 count=1 2>/dev/null) \
        >/dev/null 2>/dev/null
}

function is_pin_screen {
    if [ `dd if=/dev/fb0 bs=1 count=1 2>/dev/null | tr '\x00\xff' '01'` -eq 0 ]
    then
        return 0
    else
        return 1
    fi
}

last_wake_count=`cat /sys/power/wakeup_count`

# On first start, just create a new TOTP code, regardless.
totp_rm_config

if is_pin_screen
then
    pinentry=1
else
    pinentry=0
fi

while [ true ]
do
    # Detect a wakeup by looking at the /sys/power/wakeup_count
    cur_wake_count=`cat /sys/power/wakeup_count`

    # If the two wake counts are the same
    if [ $cur_wake_count -eq $last_wake_count ]
    then
        # Status quo unless pinentry

        # If the pinentry was shown last time, check the first pixel of the framebuffer
        # If the ifrst pixel is black, the pin entry screen is up still, so mangle the config
        if [ $pinentry -eq 1 ] && is_pin_screen
        then
            echo "`date +%FT%T -u` Continued pinentry detected" >&2
            totp_rm_config
        else
            pinentry=0
        fi
    else
        echo "`date +%FT%T -u` New pinentry detected" >&2
        pinentry=1
        totp_rm_config
    fi
    last_wake_count=$cur_wake_count
    sleep 1
done
