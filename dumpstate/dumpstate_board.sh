#!/vendor/bin/sh
#
# dumpstate_board: live qpnp-fg + smbcharger capture.
# Names: qpnp-fg registers "bms"; qpnp-smbcharger registers "battery" and "dc";
# USB gadget psy is "usb". Walk whatever is there; never invent SoC.
# talkman-cci-scan/scan is READ-ONLY (a write starts a CCI bus walk).
#

echo "------ TALKMAN dumpstate_board ------"

PSY_ROOT=/sys/class/power_supply

if [ ! -d "$PSY_ROOT" ]; then
    echo "------ $PSY_ROOT: missing ------"
else
    echo "------ $PSY_ROOT ------"
    ls -l "$PSY_ROOT"
fi

dump_file() {
    path="$1"
    if [ ! -e "$path" ]; then
        echo "------ $path: missing ------"
        return
    fi
    if [ ! -r "$path" ]; then
        echo "------ $path: not readable ------"
        return
    fi
    echo "------ $path ------"
    cat "$path"
}

dump_psy() {
    name="$1"
    dir="$PSY_ROOT/$name"
    if [ ! -d "$dir" ]; then
        echo "------ power_supply $name: missing ------"
        return
    fi
    echo "------ power_supply $name ------"
    ls -l "$dir"
    dump_file "$dir/uevent"
    for f in "$dir"/*; do
        [ -e "$f" ] || continue
        base="${f##*/}"
        [ "$base" = "uevent" ] && continue
        [ -d "$f" ] && continue
        [ -L "$f" ] && continue
        dump_file "$f"
    done
}

# Required psy (Health 2.1 / QA-CHECKLIST). Dump even if missing so the
# bugreport shows ENOENT instead of a fake 50%.
dump_psy battery
dump_psy bms
dump_psy usb
dump_psy dc

# Any extra psy the kernel registered (parallel, bcl, …).
if [ -d "$PSY_ROOT" ]; then
    for d in "$PSY_ROOT"/*; do
        [ -d "$d" ] || continue
        name="${d##*/}"
        case "$name" in
            battery|bms|usb|dc) continue ;;
        esac
        dump_psy "$name"
    done
fi

# Last CCI scan buffer only. Never echo a slave-id into scan.
for p in \
    /sys/kernel/debug/talkman-cci-scan/scan \
    /sys/kernel/debug/talkman_cci_scan/scan \
    /d/talkman-cci-scan/scan
do
    dump_file "$p"
done
