# Install LineageOS 18.1 on talkman (physical telephone)

This file is a **procedure**. It records one successful install of unofficial LineageOS 18.1 on a **Lumia 950 RM-1104** (`talkman`, board **4VM_08r**, MSM8992). Dual SIM RM-1118 / **4VM_08d** is not this product.

This is **not** an official LineageOS product. Do not upload the ROM zip to a public download site.

Vocabulary follows **ASD-STE100** Simplified Technical English (Issue 9) style. This check is not a check against the official Part 2 dictionary.

---

## Purpose

Install `lineage_talkman-userdebug` on a telephone that already runs Windows 11 ARM (WOA). Keep factory DPP WLAN/BT. Keep EFS dumps.

Do not use a stub camera. Do not invent a slave-id (rear write **0x20** / chip **0x0230** is measured). Do not mark P0 Working without `out/qa-*` logs.

---

## Result of this procedure (2026-09-02)

The telephone boots LineageOS 18.1 to the home screen. Identity on this telephone:

`lineage_talkman-userdebug 11 RQ3A.211001.001 eng.deck.20260901.182829`

`sys.boot_completed=1`. Display 1440×2560 ON. ADB product `talkman`, model `Lumia_950`.

| Function | On-device result | P0 claim |
|---|---|---|
| Display | 1440×2560 at 60 Hz, Duke command-mode | Usable. Not a panel QA pass |
| USB ADB | `g_android`, `androidboot.usbconfigfs=0` | Works |
| Wi-Fi | QCA6174 PCIe, factory MAC from DPP, DHCP, ping 8.8.8.8 / 1.1.1.1 | Works on this telephone. Not a campaign claim |
| Loudspeaker | `STREAM_MUSIC` device speaker, volume 11/15, ringtone plays | Works on this telephone |
| Battery UI | `dumpsys battery` live percent and voltage. Not 50% | **Working on this telephone** |
| Charge | USB SDP 5 V / 500 mA, charging enabled, status Full. No PD | **Working on this telephone** (USB cable). Qi pad not tested |
| GPS | `loc_eng_start`. 0 satellites. `ril-daemon` restarts. MPSS offline | **Not Working** |
| Camera | HAL **1** device, probe `mot_imx230`, CCI1 ACK 0x20 / 0x0230. Snap `openCamera` rc 0. Preview fails (`startPreview`, ISP 0x0). No JPEG | **Not Working** |
| QS flashlight | GPIO torch `led:flash_torch` works. Tile still uses CameraManager | Torch sysfs works |
| RIL | `ril-daemon` exit 1 | P2 |

Logs: workspace `out/qa-firstboot-*`, `out/qa-gps-camera`, `out/qa-camera/snap-launch.log`, `out/qa-pre-steamos-20260902/` (not in Git).

On-device patches in **On-device commands** die on a reflash of vendor or system. Source already has the VINTF fix. LifeTimer must not be in the next zip.

---

## Warnings

1. This procedure **deletes WOA** (GPT name `Windows`) and MMOS.
2. Do not run stock `partition.sh` a second time after Android GPT exists.
3. Do not run `installer.bat` again on a telephone that already has Android GPT.
4. Do not flash an empty 70 MiB `modem.img`. Verify `mba.b00` and `modem.mdt` first.
5. Windows 11 has no `wmic`. The stock `installer.bat` backup rename fails. EFS dump still exists.
6. TWRP is Omni `bullhead`. The ROM zip asserts `talkman`. RAM-boot TWRP does not change `ro.product.device`.
7. Volume keys during the Windows logo are **UEFI**, not LK2ND.
8. Host PC drives `D:` and `E:` are the PC SSD. They are not the telephone. The telephone EFIESP in this install was `H:`.
9. Do not reboot the telephone unless the operator asks. Volume keys during the logo change the boot path.

---

## Host files (this PC)

Build the zip on **ext4** (SteamOS `/home/deck/android/los-18.1`). Do not `repo sync` onto NTFS.

| Item | Path on the Windows host used for this install |
|---|---|
| ROM zip | `C:\phone\flash\lineage-18.1-20260901-UNOFFICIAL-talkman.zip` |
| Zip copy with TWRP assert removed | `C:\phone\flash\lineage-18.1-20260901-UNOFFICIAL-talkman-twrp.zip` |
| Installer | `C:\phone\mirrors\installer\installer.bat` |
| TWRP | `C:\phone\mirrors\installer\DATA\twrp.img` |
| Modem files | `C:\phone\mirrors\installer\DATA\modem-fw\` (`image/mba.b00`, `image/modem.mdt`) |
| Packed modem | `C:\phone\mirrors\installer\DATA\modem.img` (73400320 bytes FAT16) |
| ADB / fastboot | `C:\phone\mirrors\installer\bin\adb.exe`, `fastboot.exe` |
| LK2ND payload | `C:\phone\mirrors\installer\DATA\emmc_appsboot.mbn` |
| Zadig | `C:\phone\tools\zadig\zadig.exe` |
| WPinternals | `C:\Users\nizb0\Documents\Lumia950-WOA\woa-tools\WPInternals-2.9.2-x64\WPinternals.exe` |
| GPSTest APK | `C:\phone\flash\GPSTest-osmdroid-v3.10.6.apk` (package `com.android.gpstest.osmdroid`) |

Lunch: `lineage_talkman-userdebug`. Kernel: `mmo_defconfig`. `TARGET_NO_BOOTLOADER := true`. USB: CAF 3.10 `g_android`, **not** USB_CONFIGFS. Camera: `persist.camera.HAL3.enabled=0` (QCamera2 HAL1).

---

## USB IDs

| Mode | VID:PID | Windows need |
|---|---|---|
| LK2ND fastboot | `18D1:D00D` | WinUSB. DeviceInterfaceGUID `{F72FE0D4-CBCB-407d-8814-9ED673D0DD6B}` (Google). libwdi default GUID makes `fastboot devices` empty |
| TWRP ADB | `18D1:D001` | Android Composite ADB |
| Android ADB | `18D1:4EE7` | Android Composite ADB |
| UEFI BootMgr | `045E:0A02` | Lumia BootMgr |
| UEFI mass storage | `045E:9006` | Whole eMMC. Volume **Up** |

Stock `android_winusb.inf` lists PID **D001**, not **D00D**. Device Manager shows Error `CM_PROB_FAILED_INSTALL` until Zadig WinUSB + Google GUID.

Zadig: Options → List All Devices → `Android` PID `D00D` → WinUSB → Advanced: set Device Interface GUID to the Google GUID above → Replace Driver. Then unplug and plug USB. `fastboot devices` must print a serial.

---

## Volume keys (UEFI vs LK2ND)

| When | Key | Result |
|---|---|---|
| Windows logo (UEFI) | Volume **Up** | Mass storage (`EFIESP`) |
| Windows logo (UEFI) | Volume **Down** | Windows Phone boot menu |
| Windows logo (UEFI) | No key | BCD → bootshim → LK2ND → Android |
| After the logo (LK2ND) | Volume **Down** | fastboot `18D1:D00D` (TWRP if recovery was flashed) |

LK2ND panel in Little Kernel is not complete. Fastboot can be black. Watch the PC.

After Android is installed: hold Volume **Down** **after** the Windows logo to enter LK2ND fastboot. Then `fastboot boot twrp.img` or boot recovery. Do not hold Volume Down **during** the logo (that is the WP menu).

---

## Procedure

This is the path that **worked** on this RM-1104. Do not start from step 1 again if Android GPT already exists. Then use **Return from SteamOS**.

### 1. Unlock mass storage (WOA)

1. Connect the telephone with USB.
2. Start WPinternals.
3. Unlock the bootloader / enable mass storage if the tool asks.
4. Confirm EFIESP is a drive (this install: `H:`). Confirm BCD at `EFI\Microsoft\BOOT\BCD`. Confirm `Stage2` and space for `emmc_appsboot.mbn`.

### 2. Plant LK2ND on EFIESP

1. Run `C:\phone\mirrors\installer\installer.bat` as Administrator.
2. Select the EFIESP folder (BCD at `EFI\Microsoft\BOOT\BCD`).
3. Wait for: Replacing BCD, bootshim, developermenu, LK2ND.
4. If the script asks for MainOS: on WOA the GPT name is `Windows`, not `MainOS`. A patched `partition.sh` maps `Windows` → MainOS. **Do not answer n** if the goal is Android. That abort leaves Windows. The batch file can still `adb reboot bootloader` (`wmic` error does not stop it).
5. Backup rename on Windows 11 fails (`wmic` missing). Copy `C:\phone\mirrors\installer\backup` by hand to a dated folder (this install: `backup-2026-09-01_2352`).
6. Eject the telephone. Reboot with **no volume key**.
7. The telephone must enter LK2ND. If Windows USB shows `18D1:D00D` and `fastboot devices` is empty, set the Google DeviceInterfaceGUID and restart the device node.

### 3. RAM-boot TWRP

```
fastboot boot C:\phone\mirrors\installer\DATA\twrp.img
adb devices
```

Wait for ADB `recovery`. TWRP product is `bullhead`. Screen can work. Later `init.svc.recovery` can restart if `fb0` open fails (`EPERM`). ADB can still work. Do not wait on TWRP UI if `fb0` loops.

### 4. Push modem files and dump EFS

```
adb push C:\phone\mirrors\installer\DATA\modem-fw /modem-fw
adb push C:\phone\mirrors\installer\partition.sh /
adb shell bash /partition.sh
adb pull /backup C:\phone\mirrors\installer\backup
```

The script dumps APDP, DBI, DDR, DPO, DPP, LIMITS, MODEM_FS*, SEC, SSD, UEFI_* to `/backup`. Pull `/backup` to the PC. Do not use the `wmic` date rename.

### 5. WOA GPT (do not use stock MainOS/Data)

WOA names:

- `Windows` (large NTFS) — treat as MainOS. **Delete** this for Android.
- No GPT `Data`.
- `EFIESP` — keep.
- `SYSTEM` (small, flags boot,esp) — leftover ESP. Clear boot/esp. Do not format this as Android `boot`.
- `MMOS` — delete.
- `MSR` — leftover.

If `parted mkpart` fails alignment after delete, use `mkandroid.sh`:

- First free 1 MiB-aligned sector after MSR: **571392s**
- `parted --script -a none unit s mkpart ...`
- Format **by GPT number**, not `grep -w boot` (that matches leftover SYSTEM flags `boot, esp` and can run `mke2fs` on p39).

Android GPT used on this telephone:

| GPT | Name | Notes |
|---|---|---|
| 35 | EFIESP | Keep. LK2ND `emmc_appsboot.mbn` |
| 36 | aboot | fat16. Copy LK2ND here. Keep EFIESP copy |
| 41 | boot | raw `boot.img` (no ext4 required) |
| 42 | recovery | TWRP image |
| 43 | misc | |
| 44 | modem | fat16 70 MiB. MBA/MPSS |
| 45 | cache | |
| 46 | persist | WLAN MAC, BT |
| 54 | vendor | 260 MiB |
| 55 | system | 3072 MiB |
| 56 | userdata | rest |

`by-name` Android names appear only after a kernel that reads the new GPT. In the same TWRP session, make the links:

```
ln -sf /dev/block/mmcblk0pNN /dev/block/platform/soc.0/f9824900.sdhci/by-name/<name>
```

### 6. Populate modem and provision

1. Mount modem p44 vfat. Copy `/modem-fw/image/*` to `/modem/image/`. Confirm `mba.b00` and `modem.mdt`.
2. Copy `EFIESP/emmc_appsboot.mbn` to aboot. **Keep** the EFIESP copy (UEFI still loads LK2ND from EFIESP).
3. Run `provision.sh`: copy MODEM_FS* to modemst*, write `/persist/wlan_mac.bin` from `DPP/QCOM/WLAN.PROVISION`, write `/persist/bdaddr.txt` from `BT.PROVISION`. Do not invent a MAC. Do not publish the factory MAC.
4. `dd` TWRP onto recovery p42.

Optional later: `fastboot flash recovery twrp.img` and `fastboot flash modem modem.img` after `--verify-only`.

### 7. Install the zip

The updater-script asserts `ro.product.device == talkman`. TWRP is `bullhead`. `setprop` cannot change `ro.*`.

Two methods that work:

**A. Patch a copy of the zip** (keep the original):

1. Copy `lineage-18.1-20260901-UNOFFICIAL-talkman.zip` to `...-talkman-twrp.zip`.
2. In `META-INF/com/google/android/updater-script`, remove the `getprop("ro.product.device")` / `ro.build.product` abort for `talkman`.
3. Sideload or `twrp install` that copy.

**B. Run `update-binary` in the TWRP shell** (this install used this path after `twrp install` hung):

```
adb push C:\phone\flash\lineage-18.1-20260901-UNOFFICIAL-talkman.zip /data/lineage-talkman.zip
adb shell
# unzip the updater into /tmp/updater if needed, then:
/tmp/updater/META-INF/com/google/android/update-binary 3 1 /data/lineage-talkman.zip
```

TWRP CLI `twrp install` waits if recovery UI is in a crash loop (`cannot open fb0`). Use method B then.

Success on this telephone:

- system 382510 blocks
- vendor 57343 blocks
- `boot.img` magic `ANDROID!` on p41
- `ro.lineage.version=18.1-20260901-UNOFFICIAL-talkman`

### 8. First Android boot (ADB unauthorized)

1. `adb reboot` from TWRP. No volume key during the Windows logo.
2. USB becomes `18D1:4EE7`. ADB is **unauthorized**. TWRP reports `bullhead`, so the RSA dialog can fail or hide behind a black screen.
3. Reboot to TWRP (Volume Down **after** the logo → fastboot → `fastboot boot twrp.img`).
4. Userdata is ext4, not encrypted on this first boot. Inject the PC key:

```
adb push %USERPROFILE%\.android\adbkey.pub /data/misc/adb/adb_keys
adb shell chmod 640 /data/misc/adb/adb_keys
adb shell chown 1000:2000 /data/misc/adb/adb_keys
```

5. Reboot to Android. `adb devices` must show `device`.

### 9. Black screen: VINTF (this zip)

SurfaceFlinger abort: `gralloc-mapper is missing`.

Cause: `hwservicemanager` VINTF parse error `HAL "android.hardware.vibrator" has a conflict`. `DEVICE_MANIFEST_FILE` listed vibrator, health, and power. The HAL packages also ship `vintf_fragments`. The device manifest failed. Mapper did not register.

On-device fix (dies on vendor reflash). `adb remount` remounts **vendor**. Then:

```
adb root
adb remount
adb shell rm /vendor/etc/vintf/manifest/android.hardware.vibrator@1.0.xml
adb shell rm /vendor/etc/vintf/manifest/android.hardware.health@2.1.xml
adb shell rm /vendor/etc/vintf/manifest/android.hardware.power@1.0.xml
adb shell stop hwservicemanager
adb shell start hwservicemanager
```

After `hwservicemanager` restarts, PowerManager can wait on `android.system.suspend@1.0` (old pid). Then:

```
adb shell start system_suspend
```

Mapper / allocator / composer must register. Backlight sysfs must be writable. Display then works.

Source fix already in this tree: do not list those HALs in `manifest.xml`. Keep the fragments from the services.

### 10. Boot animation loop: LifeTimer

```
IllegalStateException: Signature|privileged permissions not in privapp-permissions whitelist:
{com.lge.lifetimer (/system/priv-app/LifeTimerService): android.permission.READ_PRIVILEGED_PHONE_STATE}
```

System-as-root: remount **`/`**, not `/system`.

```
adb root
adb shell mount -o remount,rw /
adb shell rm -rf /system/priv-app/LifeTimerService
adb shell rm -rf /system/priv-app/HiddenMenu
adb reboot
```

Do not package LifeTimerService. `extract-files.sh` already bans LifeTimer dests; this zip still had the APK. DiagMon can still be packaged. DCMO can still be on the image.

### 11. Lineage setup

Finish the setup wizard on the telephone. Do not reboot the telephone during setup unless the operator asks.

After setup, Lineage can set **ADB Root access is disabled by system setting**. `adb root` then fails. Re-enable:

```
adb shell settings put global development_settings_enabled 1
adb shell settings put global root_access 3
adb shell settings put secure root_access 3
adb shell setprop persist.sys.root_access 3
adb root
```

### 12. Tests that worked on this telephone

**Wi-Fi.** Settings → Network. QCA6174 / AR6320 PCIe. Does **not** need MPSS. Factory MAC from DPP / persist. Confirm DHCP and:

```
adb shell ping -c 3 8.8.8.8
adb shell ping -c 3 1.1.1.1
```

Do not publish the SSID, BSSID, or factory MAC.

**Loudspeaker.** Side volume rocker. Settings → Sound. Or open app **Eleven** and play:

`/system/product/media/audio/ringtones/Orion.ogg`

(`AudioPreviewActivity`). `dumpsys audio` must show `STREAM_MUSIC` device **speaker**. The earpiece is the top call speaker, not this path.

**GPIO torch.** Root:

```
echo 1 > /sys/class/leds/led:flash_torch/brightness
echo 0 > /sys/class/leds/led:flash_torch/brightness
```

That node is TLMM GPIO 12 (`gpio-leds`). It works. Do **not** also write `led:torch_0` or `led:torch_1` (PMI qpnp). A write to `led:torch_0` lit the **red notification LED** on this telephone. Lights HAL `setFlashlight` must use **only** `led:flash_torch`.

PowerShell on the PC: do not nest `adb shell "... \"$n=\""` (quote parse fails). Run one `echo` per node.

QS tile still uses `CameraManager.setTorchMode` because `android.hardware.camera.flash` is advertised. 0 camera devices → text "camera in use". That is not a GPIO failure.

**Battery UI and USB charge.** `dumpsys battery` on this telephone: live percent and voltage, Li-ion, USB `online`, SDP 5 V / 500 mA, `charging_enabled`, status Full. Not a hardcoded 50%. **Working on this telephone.** Qi pad is not tested. `bms/charge_full` is still a bad health value; that is not the charge path.

**GPS (failed).** Sideload `GPSTest-osmdroid-v3.10.6.apk`. Status empty. `loc_eng_start` / inject_time run. 0 SV / CN0. `mTopHalCapabilities=0x0`. `ril-daemon` restarts. Subsys: venus / AR6320 / adsp / modem — modem **OFFLINE**. Wi-Fi stays up without MPSS. GPS needs MPSS.

**Camera (failed).** Snap is `/system/system_ext/priv-app/Snap/Snap.apk`. The icon is **not** missing because the APK is missing. `SetActivitiesCameraReceiver` puts `CameraLauncher` in `disabledComponents` when the HAL reports 0 cameras.

```
adb shell pm enable org.lineageos.snap/com.android.camera.CameraLauncher
adb shell pm disable org.lineageos.snap/com.android.camera.SetActivitiesCameraReceiver
```

Open Snap. Crash:

```
CameraHolder: fail to connect Camera:-1
CAM_PhotoModule: Failed to open camera:0
ArrayIndexOutOfBoundsException: length=0; index=0
PhotoModule.initializeFocusManager
```

The daemon probed bullhead **imx377**, not the XML name, because
`sensor_init_probe()` in `libmmcamera2_sensor_modules.so` never reads the XML. It
walks a sensor list compiled into that blob — `imx214`, `imx230`, `s5k3m2xx`,
`imx377`, `s5k3m2xm`, `ov4688`, `imx258`, `ov5693` — and opens
`/vendor/lib/libmmcamera_<name>.so` for each one. `mot_imx230` is not in that list,
so the Clark library was never opened, and the only two libraries on the image were
the leftover `libmmcamera_imx377.so` and `libmmcamera_ov5693.so`.

Fix (2026-09-02): the two leftovers are no longer packaged, and
`libmmcamera_mot_imx230.so` is installed a second time as `libmmcamera_imx230.so`
so the `imx230` slot finds it. The probe name comes from the file name, but the
sensor name that reaches the kernel comes from `sensor_slave_info` inside the
library, so the slot still probes as `mot_imx230`. This is the real Clark library
under a second name, not a stub.

Measured on the telephone after the change:

```
sensor_probe:323[imx230]probe failed.
msm_sensor_match_id: mot_imx230: read id failed
msm_cci_irq:1090 MASTER_1 error 0x40000000
```

One probe, and it is the XML name. No imx377 and no ov5693.

Later the same day (boot-only flashes, kernel `#21`): CCI1 **does** ACK. Rear
write address **0x20**, Sony chip **0x0230** at register **0x0016**. CAF first
cell is the 8-bit write address. Clark revision I2C still sends **0x34**; the
kernel uses **0x20**. `dumpsys media.camera` shows **1** device. `openCamera`
returns rc 0.

Snap is still **Not Working**:

1. First open: `PhotoModule.initializeFocusManager` `length=0; index=0`.
2. Second open: `startPreview failed`. Daemon:
   `isp_util_map_streams: failed: sensor resolution: 0x0` then
   `Only session stream can be linked before ISP res allocation`.

No JPEG. Do not ship a stub camera. Next: a live preview and a still on
`/sdcard/DCIM`.

### 13. Enter TWRP after Android is installed

1. Reboot. Let the Windows logo pass. **Then** hold Volume Down.
2. PC shows `18D1:D00D`. `fastboot devices` must list the serial.
3. `fastboot boot C:\phone\mirrors\installer\DATA\twrp.img` or boot the flashed recovery.

Normal reboot: no volume key during the logo.

---

## Failures recorded on this install

### installer.bat / Windows 11

- `'wmic' is not recognized`. Backup folder rename becomes `backup-~6,2datetime` in PowerShell.
- After MainOS `n`, the bat still reboots to bootloader and waits (`< waiting for any device >` until Zadig).

### GPT / format

- Stock `grep -w boot` formatted leftover WOA SYSTEM p39 (flags `boot, esp`).
- `parted mkpart` from 278 MiB failed alignment (`569344` vs `569856`). Use sector start **571392s**, `-a none`.

### Display / first boot (black screen)

See procedure step 9. VINTF conflict → no mapper → SurfaceFlinger abort.

### Boot animation loop

See procedure step 10. LifeTimer privapp whitelist.

### Snap Camera icon missing / crash on load

See procedure step 12. Not a missing APK.

### QS flashlight

See procedure step 12. GPIO works. Tile uses CameraManager.

### GPS empty

See procedure step 12. Needs MPSS.

---

## On-device commands that worked after first boot

```
# VINTF (vendor remount)
rm /vendor/etc/vintf/manifest/android.hardware.vibrator@1.0.xml
rm /vendor/etc/vintf/manifest/android.hardware.health@2.1.xml
rm /vendor/etc/vintf/manifest/android.hardware.power@1.0.xml
stop hwservicemanager
start hwservicemanager
start system_suspend

# privapp (system-as-root: remount / )
mount -o remount,rw /
rm -rf /system/priv-app/LifeTimerService
rm -rf /system/priv-app/HiddenMenu

# ADB root after Lineage setup
settings put global development_settings_enabled 1
settings put global root_access 3
settings put secure root_access 3
setprop persist.sys.root_access 3

# Camera icon
pm enable org.lineageos.snap/com.android.camera.CameraLauncher
pm disable org.lineageos.snap/com.android.camera.SetActivitiesCameraReceiver

# Torch test (root). GPIO only. Do not write led:torch_0.
echo 1 > /sys/class/leds/led:flash_torch/brightness
echo 0 > /sys/class/leds/led:flash_torch/brightness
```

These patches die on reflash. The next zip must not need the VINTF deletes or LifeTimer rm.

---

## Reproduce (next zip)

Build host: SteamOS ext4 `/home/deck/android/los-18.1`. This Windows host cannot rebuild the kernel.

1. Land kernel DT `talkman-camera.dtsi` (`qcom,sensor-name = "mot_imx230"`, no slave-id) in the **built** `Image.gz-dtb`. Confirm the DTB strings contain `mot_imx230` and talkman-cci-scan **before** flash.
2. Keep `manifest.xml` without health / power / vibrator HAL blocks.
3. Do not install LifeTimerService.
4. Lights: write `led:flash_torch` only.
5. Camera next: ISP still reports sensor resolution **0x0**. HAL already has CameraId 0. Do not mark Working without a JPEG.
5. `lunch lineage_talkman-userdebug` then `mka bacon`.
6. Copy the zip to the Windows installer PC. Do not `repo sync` onto NTFS.
7. If Android GPT already exists: **do not** run `installer.bat` or stock `partition.sh`. Keep userdata. Flash the new zip from TWRP, or flash only `boot.img` if the change is kernel/DT.
8. If EFIESP already has LK2ND and this is a first Android GPT: start at procedure step 3.
9. Capture `out/qa-*` on the Windows host. Do not mark P0 Working without those logs.

### Return from SteamOS (this telephone already runs Android)

Do **not** reinstall. Do **not** wipe userdata.

1. Rebuild `boot.img` (and zip if vendor/system changed) on SteamOS.
2. Copy artifacts to `C:\phone\flash\`.
3. Enter LK2ND fastboot (Volume Down **after** the logo).
4. `fastboot boot twrp.img` or `fastboot flash boot boot.img`.
5. If only DT/kernel: flash boot. Reboot. Run CCI scan. Capture `out/qa-*`.
6. If a full zip: `update-binary` or patched zip as in step 7. VINTF source fix and no LifeTimer must be in that zip.

---

## GitHub (personal)

Write is **archienz** only.

| Item | URL |
|---|---|
| Device tree | https://github.com/archienz/android_device_msft_talkman |
| Vendor | https://github.com/archienz/android_vendor_msft_talkman |
| Repository README (GitHub home) | https://github.com/archienz/android_device_msft_talkman |
| GitHub Pages hub | https://archienz.github.io/android_device_msft_talkman/ |
| This procedure on Pages | https://archienz.github.io/android_device_msft_talkman/INSTALL.html |
| This procedure in Git | `docs/INSTALL.md` on branch `lineage-18.1-talkman-hw` |

Do not open pull requests on Android4Lumia950 unless the owner asks.

Do not publish:

- The ROM zip
- Schematic PDF / schematic-png
- Factory MAC / serial / SSID as a public table
- Kernel tree to an archienz remote (no archienz kernel remote)

### Enable GitHub Pages (once)

Source: branch `lineage-18.1-talkman-hw`, folder `/docs`. Jekyll reads `docs/_config.yml`. Home page is `docs/index.md`. `INSTALL.md` becomes `INSTALL.html`.

GitHub website:

1. Open https://github.com/archienz/android_device_msft_talkman/settings/pages
2. Build and deployment → Source: **Deploy from a branch**
3. Branch: `lineage-18.1-talkman-hw` / `/docs`
4. Save. Wait for the Actions run **pages build and deployment**.

API (this install used this path):

```
gh api -X POST repos/archienz/android_device_msft_talkman/pages -f build_type=legacy -f source[branch]=lineage-18.1-talkman-hw -f source[path]=/docs
```

If Pages already exists, use `PUT` / `PATCH` instead of `POST`.

Do **not** push this text to `Android4Lumia950/Android4Lumia950.github.io`. That site is community. This install is personal.

### Update the GitHub repository page and the Pages site

The repository home page is `README.md` (Purpose, Progress, Changes). The Pages site is the same repository `docs/` folder.

1. Edit `README.md` Progress and Changes (ASD-STE100. No Wave / campaign / LIVE / agent IDs).
2. Edit `docs/INSTALL.md` if the procedure or findings change.
3. Edit `docs/index.md` if the hub links change.
4. Copy a local backup to the workspace if needed (`C:\phone\docs\INSTALL-TALKMAN-LOS18.md`).
5. Commit as **archienz** (`archienz@users.noreply.github.com`). Do not use EpicLPer as author.
6. Push **only** the personal remote:

```
git -C C:\phone\mirrors\android_device_msft_talkman push archienz lineage-18.1-talkman-hw
```

Do **not** `git push origin` (origin is Android4Lumia950).

7. Confirm https://github.com/archienz/android_device_msft_talkman shows the new README.
8. Wait for Actions **pages build and deployment**. Then open:
   - https://archienz.github.io/android_device_msft_talkman/
   - https://archienz.github.io/android_device_msft_talkman/INSTALL.html
9. If the site is stale, wait one minute and hard-refresh. Confirm the date in **Result of this procedure**.

---

## Git author mistake (apology)

Some older commits show **EpicLPer**. EpicLPer did not write them. **archienz** did. New commits use archienz.
