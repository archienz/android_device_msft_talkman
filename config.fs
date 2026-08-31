[vendor/bin/qmuxd]
mode: 0700
user: AID_RADIO
group: AID_SHELL
caps: BLOCK_SUSPEND

[vendor/bin/mm-qcamera-daemon]
mode: 0700
user: AID_CAMERA
group: AID_SHELL
caps: SYS_NICE

[data/misc/camera/]
mode: 0770
user: AID_CAMERA
group: AID_CAMERA
caps: 0

[data/vendor/camera/]
mode: 0770
user: AID_CAMERA
group: AID_CAMERA
caps: 0

[persist/camera/]
mode: 0770
user: AID_CAMERA
group: AID_CAMERA
caps: 0

[data/nfc/]
mode: 0770
user: AID_NFC
group: AID_NFC
caps: 0

[data/nfc/param/]
mode: 0770
user: AID_NFC
group: AID_NFC
caps: 0

[data/vendor/nfc/]
mode: 0770
user: AID_NFC
group: AID_NFC
caps: 0

[vendor/bin/loc_launcher]
mode: 0755
user: AID_GPS
group: AID_GPS
caps: SETUID SETGID

[vendor/bin/slim_daemon]
mode: 0755
user: AID_GPS
group: AID_GPS
caps: NET_BIND_SERVICE

[data/misc/location/]
mode: 0770
user: AID_GPS
group: AID_GPS
caps: 0

[data/vendor/location/]
mode: 0770
user: AID_GPS
group: AID_GPS
caps: 0

[persist/]
mode: 0771
user: AID_SYSTEM
group: AID_SYSTEM
caps: 0

[firmware/]
mode: 0771
user: AID_SYSTEM
group: AID_SYSTEM
caps: 0
