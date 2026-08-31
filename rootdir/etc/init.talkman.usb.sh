#!/vendor/bin/sh
# Talkman g_android bring-up. CAF 3.10 has no USB_CONFIGFS.
# Keep sys.usb.configfs=0 and android_usb. UFP/sink only; no PD.

SSUSB=/sys/devices/soc.0/f9200000.ssusb
UDC_DT=f9200000.dwc3

write() {
    [ -e "$1" ] || return 0
    echo -n "$2" > "$1"
}

write "$SSUSB/mode" peripheral
write "$SSUSB/$UDC_DT/mode" peripheral
write /sys/class/dual_role_usb/otg_default/mode ufp

setprop sys.usb.configfs 0
write /sys/class/android_usb/android0/f_ffs/aliases adb
write /sys/class/android_usb/android0/iSerial "$(getprop ro.serialno)"
write /sys/class/android_usb/android0/iManufacturer "$(getprop ro.product.manufacturer)"
write /sys/class/android_usb/android0/iProduct "$(getprop ro.product.model)"

usb=$(getprop persist.sys.usb.config)
if [ -z "$usb" ]; then
    setprop persist.sys.usb.config adb
fi
