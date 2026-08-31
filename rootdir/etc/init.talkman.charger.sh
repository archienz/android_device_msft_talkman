#!/vendor/bin/sh
# Talkman PMI8994 smbcharger off-mode ICL (on charger).
# Cable ceiling 5 V × 1.8 A ≈ 9 W. Qi DCIN 900 mA. No USB-PD PHY, no HVDCP.

USB_ICL_UA=1800000
DC_ICL_UA=900000
USB_VMAX_UV=5000000

write() {
    [ -e "$1" ] || return 0
    echo -n "$2" > "$1"
}

chmod_rw() {
    [ -e "$1" ] || return 0
    chmod 0664 "$1"
    chown system system "$1"
}

# qpnp-smbcharger / dwc3 usb psy may not be up when on charger runs.
i=0
while [ "$i" -lt 50 ]; do
    [ -e /sys/class/power_supply/usb/current_max ] && \
        [ -e /sys/class/power_supply/dc/current_max ] && \
        [ -e /sys/class/power_supply/battery/charging_enabled ] && break
    i=$((i + 1))
    sleep 0.1
done

chmod_rw /sys/class/power_supply/usb/current_max
chmod_rw /sys/class/power_supply/usb/voltage_max
chmod_rw /sys/class/power_supply/dc/current_max
chmod_rw /sys/class/power_supply/dc/charging_enabled
chmod_rw /sys/class/power_supply/battery/charging_enabled
chmod_rw /sys/class/power_supply/battery/battery_charging_enabled

# dwc3 usb psy CURRENT_MAX is µA; smbchg_external_power_changed applies ICL.
# voltage_max is 5 V only — never 9 V / PD / HVDCP.
write /sys/class/power_supply/usb/current_max "$USB_ICL_UA"
write /sys/class/power_supply/usb/voltage_max "$USB_VMAX_UV"

# smbcharger dc psy CURRENT_MAX is µA. Kernel also sets this from qcom,dc-psy-ma.
write /sys/class/power_supply/dc/current_max "$DC_ICL_UA"
write /sys/class/power_supply/dc/charging_enabled 1

# Unsuspend USB+DC paths and keep batt FET on (Lineage charging control may clear later).
write /sys/class/power_supply/battery/charging_enabled 1
write /sys/class/power_supply/battery/battery_charging_enabled 1
