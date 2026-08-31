#!/vendor/bin/sh
#
# Talkman QCA Rome BD_ADDR.
#  1. /persist/bdaddr.txt (installer copies DPP/QCOM/BT.PROVISION)
#  2. QCA OTP when persist is missing or a placeholder
# Analog of WCNSS g_use_otpmac=1. Do not invent a MAC.
# CAF libbt-vendor (hw_rome.c) memcpy()s ro.boot.btmacaddr over NVM tag 2.
# Zeros leave talkman nvm_tlv_3.2.bin tag 2 as zeros so the controller OTP wins.

PERSIST=/persist/bdaddr.txt
PROP=ro.boot.btmacaddr

use_otp() {
    setprop "$PROP" "00:00:00:00:00:00"
}

if [ ! -f "$PERSIST" ]; then
    use_otp
    exit 0
fi

hex=$(tr -d ' \t\r\n:' < "$PERSIST" | tr 'a-f' 'A-F')

case "$hex" in
    [0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F][0-9A-F])
        ;;
    *)
        use_otp
        exit 0
        ;;
esac

mac=$(echo "$hex" | sed 's/\(..\)/\1:/g;s/:$//')

# CAF Rome 1.0 sample (hw_rome.c), broadcast, zeros. Not factory DPP/OTP.
case "$mac" in
    00:00:00:00:00:00|FF:FF:FF:FF:FF:FF|77:78:23:01:56:22|22:22:22:22:22:22)
        rm -f "$PERSIST"
        use_otp
        exit 0
        ;;
esac

# Bit 0 = multicast, bit 1 = locally administered (lk2nd serial derivative).
b0=$((0x$(echo "$hex" | cut -c1-2)))
if [ $((b0 & 3)) -ne 0 ]; then
    rm -f "$PERSIST"
    use_otp
    exit 0
fi

chmod 0644 "$PERSIST"
setprop "$PROP" "$mac"
