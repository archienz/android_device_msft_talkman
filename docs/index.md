# Talkman LineageOS 18.1 (personal)

This Pages site is the **archienz** device-tree documentation. It is not the Android4Lumia950 community site.

| Page | What it is |
|---|---|
| [Repository README](https://github.com/archienz/android_device_msft_talkman) | Purpose, Progress, Changes |
| [Install procedure](INSTALL.md) | One physical RM-1104 install (2026-09-02): steps that worked, failures, how to reproduce, how to update this site |
| [Camera ident notes](CAMERA-IDENT.md) | CCI / sensor lab notes. Rear write address 0x20 / chip 0x0230 is measured |

P0 (battery UI, charge, GPS, camera) is **Not Working** until `out/qa-*` logs pass. Dual SIM RM-1118 is not this product.

On this telephone (2026-09-02): home screen, display 1440×2560, Wi-Fi, loudspeaker, GPIO torch. HAL lists CameraId 0 (`mot_imx230`). Snap preview fails. GPSTest empty.

Do not download a public ROM from this page. The unofficial zip is local.

Live URLs:

- Hub: https://archienz.github.io/android_device_msft_talkman/
- Install: https://archienz.github.io/android_device_msft_talkman/INSTALL.html
