#!/vendor/bin/sh
# Talkman USB: CAF 3.10 g_android only. No USB_CONFIGFS, no PD sink.
# Schematic TYPE_C + HD3SS460 SS mux + USB_VBUS. Kernel mmo-usbc holds
# POL=0 AMSEL=0 EN=1 VBUS=0 (USB, not DP, not OTG source).

SSUSB=/sys/devices/soc.0/f9200000.ssusb
UDC_DT=f9200000.dwc3
AUSB=/sys/class/android_usb/android0

write() {
    [ -e "$1" ] || return 0
    echo -n "$2" > "$1"
}

# LOS 18.1 init may try configfs; this kernel has none.
setprop sys.usb.configfs 0
setprop persist.sys.usb.configfs 0

write "$SSUSB/mode" peripheral
write "$SSUSB/$UDC_DT/mode" peripheral
write /sys/class/dual_role_usb/otg_default/mode ufp

# Mux is GPIO-programmed in mmo-usbc probe. Read-only sysfs here.
for n in \
    /sys/devices/platform/hd3ss460/mux \
    /sys/devices/soc.0/hd3ss460/mux \
    /sys/devices/hd3ss460/mux
do
    [ -e "$n" ] && cat "$n"
done
for n in \
    /sys/devices/platform/ice5lp2k/cdone \
    /sys/devices/soc.0/ice5lp2k/cdone \
    /sys/devices/ice5lp2k/cdone
do
    [ -e "$n" ] && cat "$n"
done

i=0
while [ ! -e "$AUSB/enable" ] && [ "$i" -lt 50 ]; do
    i=$((i + 1))
    sleep 0.1
done

write "$AUSB/f_ffs/aliases" adb
write "$AUSB/iSerial" "$(getprop ro.serialno)"
write "$AUSB/iManufacturer" "$(getprop ro.product.manufacturer)"
write "$AUSB/iProduct" "$(getprop ro.product.model)"
write "$AUSB/f_rndis/manufacturer" Microsoft
write "$AUSB/f_rndis/vendorID" 18D1
write "$AUSB/f_rndis/wceis" 1
write "$AUSB/f_rndis_qc/rndis_transports" BAM2BAM_IPA

usb=$(getprop persist.sys.usb.config)
if [ -z "$usb" ] || [ "$usb" = "none" ]; then
    setprop persist.sys.usb.config adb
fi
