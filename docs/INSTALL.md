# Install LineageOS 18.1 on talkman (physical telephone)

This file is a **procedure**. It records one successful install of unofficial LineageOS 18.1 on a **Lumia 950 RM-1104** (`talkman`, board **4VM_08r**, MSM8992). Dual SIM RM-1118 / **4VM_08d** is not this product.

This is **not** an official LineageOS product. Do not upload the ROM zip to a public download site.

Vocabulary follows **ASD-STE100** Simplified Technical English (Issue 9) style. This check is not a check against the official Part 2 dictionary.

---

## Purpose

Install `lineage_talkman-userdebug` on a telephone that already runs Windows 11 ARM (WOA). Keep factory DPP WLAN/BT. Keep EFS dumps.

Do not use a stub camera. Do not invent `qcom,slave-id`. Do not mark P0 Working without `out/qa-*` logs.

---

## Result of this procedure (2026-09-02)

The telephone boots LineageOS 18.1 to the home screen.

| Function | On-device result | P0 claim |
|---|---|---|
| Display | 1440×2560 at 60 Hz, Duke command-mode | Usable. Not a panel QA pass |
| USB ADB | `g_android`, `androidboot.usbconfigfs=0` | Works |
| Wi-Fi | QCA6174, factory MAC from DPP, DHCP, ping | Works on this telephone. Not a campaign claim |
| Loudspeaker | `STREAM_MUSIC` device speaker | Works on this telephone |
| Battery UI | `dumpsys battery` live percent and voltage. Not 50% | **Not Working** (no USB-meter pass) |
| Charge | USB ~500 mA in the log. No PD | **Not Working** |
| GPS | `loc_eng_start`. 0 satellites. `ril-daemon` restarts | **Not Working** |
| Camera | Snap opens, then crash. HAL probes **imx377**. 0 devices | **Not Working** |
| QS flashlight | Text "camera in use" | GPIO torch `led:flash_torch` works. Tile uses CameraManager |
| RIL | `ril-daemon` exit 1 | P2 |

Logs: workspace `out/qa-pre-steamos-20260902/` (not in Git).

---

## Warnings

1. This procedure **deletes WOA** (GPT name `Windows`) and MMOS.
2. Do not run stock `partition.sh` a second time after Android GPT exists.
3. Do not flash an empty 70 MiB `modem.img`. Verify `mba.b00` and `modem.mdt` first.
4. Windows 11 has no `wmic`. The stock `installer.bat` backup rename fails. EFS dump still exists.
5. TWRP is Omni `bullhead`. The ROM zip asserts `talkman`. RAM-boot TWRP does not change `ro.product.device`.
6. Volume keys during the Windows logo are **UEFI**, not LK2ND.

---

## Host files (this PC)

Build the zip on **ext4** (SteamOS `/home/deck/android/los-18.1`). Do not `repo sync` onto NTFS.

| Item | Path on the Windows host used for this install |
|---|---|
| ROM zip | `C:\phone\flash\lineage-18.1-20260901-UNOFFICIAL-talkman.zip` |
| Installer | `C:\phone\mirrors\installer\installer.bat` |
| TWRP | `C:\phone\mirrors\installer\DATA\twrp.img` |
| Modem files | `C:\phone\mirrors\installer\DATA\modem-fw\` (`image/mba.b00`, `image/modem.mdt`) |
| Packed modem | `C:\phone\mirrors\installer\DATA\modem.img` (73400320 bytes FAT16) |
| ADB / fastboot | `C:\phone\mirrors\installer\bin\adb.exe`, `fastboot.exe` |
| LK2ND payload | `C:\phone\mirrors\installer\DATA\emmc_appsboot.mbn` |
| Zadig | `C:\phone\tools\zadig\zadig.exe` |
| WPinternals | `C:\Users\nizb0\Documents\Lumia950-WOA\woa-tools\WPInternals-2.9.2-x64\WPinternals.exe` |

Lunch: `lineage_talkman-userdebug`. Kernel: `mmo_defconfig`. `TARGET_NO_BOOTLOADER := true`. USB: CAF 3.10 `g_android`, **not** USB_CONFIGFS.

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

---

## Volume keys (UEFI vs LK2ND)

| When | Key | Result |
|---|---|---|
| Windows logo (UEFI) | Volume **Up** | Mass storage (`EFIESP`) |
| Windows logo (UEFI) | Volume **Down** | Windows Phone boot menu |
| Windows logo (UEFI) | No key | BCD → bootshim → LK2ND → Android |
| After the logo (LK2ND) | Volume **Down** | fastboot `18D1:D00D` |

LK2ND panel in Little Kernel is not complete. Fastboot can be black. Watch the PC.

---

## Procedure

### 1. Unlock mass storage (WOA)

1. Connect the telephone with USB.
2. Start WPinternals.
3. Unlock the bootloader / enable mass storage if the tool asks.
4. Confirm EFIESP is a drive (this install: `H:`).

### 2. Plant LK2ND on EFIESP

1. Run `C:\phone\mirrors\installer\installer.bat` as Administrator.
2. Select the EFIESP folder (BCD at `EFI\Microsoft\BOOT\BCD`).
3. Wait for: Replacing BCD, bootshim, developermenu, LK2ND.
4. Eject the telephone. Reboot with **no volume key**.
5. The telephone must enter LK2ND. If Windows USB shows `18D1:D00D` and `fastboot devices` is empty, set the Google DeviceInterfaceGUID and restart the device node.

### 3. RAM-boot TWRP

1. `fastboot boot C:\phone\mirrors\installer\DATA\twrp.img`
2. Wait for ADB `recovery`.

TWRP product is `bullhead`. Screen can work. Later `init.svc.recovery` can restart if `fb0` open fails. ADB can still work.

### 4. Push modem files and dump EFS

1. `adb push C:\phone\mirrors\installer\DATA\modem-fw /modem-fw`
2. `adb push C:\phone\mirrors\installer\partition.sh /`
3. `adb shell bash /partition.sh`

The script dumps APDP, DBI, DDR, DPO, DPP, LIMITS, MODEM_FS*, SEC, SSD, UEFI_* to `/backup`. Pull `/backup` to the PC. Do not use the `wmic` date rename. Copy the folder with a PowerShell date.

### 5. WOA GPT (do not use stock MainOS/Data)

WOA names:

- `Windows` (large NTFS) — treat as MainOS. **Delete** this for Android.
- No GPT `Data`.
- `EFIESP` — keep.
- `SYSTEM` (small, flags boot,esp) — leftover ESP. Clear boot/esp. Do not format this as Android `boot`.
- `MMOS` — delete.
- `MSR` — leftover.

If the script asks "MainOS not found" on WOA, the grep is `MainOS` only. A patched `partition.sh` maps GPT `Windows` to MainOS.

**Do not answer n on MainOS** if the goal is Android. That abort leaves Windows in place. The batch file can continue to `adb reboot bootloader` anyway (`wmic` error does not stop it).

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

`ln -sf /dev/block/mmcblk0pNN /dev/block/platform/soc.0/f9824900.sdhci/by-name/<name>`

### 6. Populate modem and provision

1. Mount modem p44 vfat. Copy `/modem-fw/image/*` to `/modem/image/`. Confirm `mba.b00` and `modem.mdt`.
2. Copy `EFIESP/emmc_appsboot.mbn` to aboot. **Keep** the EFIESP copy (UEFI still loads LK2ND from EFIESP).
3. Run `provision.sh`: copy MODEM_FS* to modemst*, write `/persist/wlan_mac.bin` from `DPP/QCOM/WLAN.PROVISION`, write `/persist/bdaddr.txt` from `BT.PROVISION`. Do not invent a MAC.
4. `dd` TWRP onto recovery p42.

Optional later: `fastboot flash recovery twrp.img` and `fastboot flash modem modem.img` after `--verify-only`.

### 7. Install the zip

The updater-script asserts `ro.product.device == talkman`. TWRP is `bullhead`. `setprop` cannot change `ro.*`.

Options:

- Patch a **copy** of the zip: remove the assert. Keep the original zip.
- Or run the zip `update-binary` after `setprop` fails (this install used that path).

TWRP CLI `twrp install` waits if recovery UI is in a crash loop (`cannot open fb0`). Then run:

```
/tmp/updater/META-INF/com/google/android/update-binary 3 1 /data/<zip>
```

Success on this telephone:

- system 382510 blocks
- vendor 57343 blocks
- `boot.img` magic `ANDROID!` on p41
- `ro.lineage.version=18.1-20260901-UNOFFICIAL-talkman`

### 8. First Android boot

1. `adb reboot` from TWRP. No volume key during the Windows logo.
2. USB becomes `18D1:4EE7`. ADB is **unauthorized** until the RSA dialog (black screen can hide it).
3. Inject the PC `adbkey.pub` into `/data/misc/adb/adb_keys` from TWRP (userdata is ext4, not encrypted on this first boot).
4. Enable Lineage rooted debugging: `settings put global development_settings_enabled 1`, `persist.sys.root_access=3`.

---

## Failures recorded on this install

### installer.bat / Windows 11

- `'wmic' is not recognized`. Backup folder rename becomes `backup-~6,2datetime` in PowerShell.
- After MainOS `n`, the bat still reboots to bootloader and waits.

### GPT / format

- Stock `grep -w boot` formatted leftover WOA SYSTEM p39 (flags `boot, esp`).
- `parted mkpart` from 278 MiB failed alignment (`569344` vs `569856`). Use sector start **571392s**, `-a none`.

### Display / first boot (black screen)

SurfaceFlinger abort: `gralloc-mapper is missing`.

Cause: `hwservicemanager` VINTF parse error:

```
HAL "android.hardware.vibrator" has a conflict
```

`DEVICE_MANIFEST_FILE` listed vibrator, health, and power. The HAL packages also ship `vintf_fragments`. The device manifest failed. Mapper did not register.

On-device fix (does not survive a reflash of vendor):

- Delete `/vendor/etc/vintf/manifest/android.hardware.vibrator@1.0.xml`
- Delete `android.hardware.health@2.1.xml`
- Delete `android.hardware.power@1.0.xml`

Source fix: do not list those HALs in `manifest.xml`. The fragments stay.

After that, SurfaceFlinger runs. Display works.

### Boot animation loop

```
IllegalStateException: Signature|privileged permissions not in privapp-permissions whitelist:
{com.lge.lifetimer (/system/priv-app/LifeTimerService): android.permission.READ_PRIVILEGED_PHONE_STATE}
```

Remove `/system/priv-app/LifeTimerService`. Do not package it. `extract-files.sh` already bans LifeTimer dests; the zip still had the APK.

### Snap Camera icon missing

`CameraLauncher` is in `disabledComponents`. `SetActivitiesCameraReceiver` disables the icon when the HAL has 0 cameras.

```
pm enable org.lineageos.snap/com.android.camera.CameraLauncher
pm disable org.lineageos.snap/com.android.camera.SetActivitiesCameraReceiver
```

### Snap crash on load

```
CameraHolder: fail to connect Camera:-1
ArrayIndexOutOfBoundsException: length=0; index=0
PhotoModule.initializeFocusManager
```

Daemon log:

```
msm_sensor_match_id: imx377: read id failed
CCI MASTER_1 error
probe failed ov5693 / ov4688 / imx258
```

Userspace XML is `mot_imx230`. The **flashed DTB** has `qcom,camera@0` and **no** `mot_imx230`. Rebuild `boot.img` with `talkman-camera.dtsi`. Do not invent `qcom,slave-id`. Run CCI scan after that kernel.

### QS flashlight

Tile uses `CameraManager.setTorchMode`. Camera HAL has 0 devices. Text: camera in use.

GPIO torch `led:flash_torch` (TLMM 12) works. Do not also write `led:torch_0` (PMI qpnp). That write can light the red indicator. Lights HAL must use **only** `led:flash_torch`.

### GPS empty

`loc_eng_start` runs. 0 SV. NTP inject over Wi-Fi works. `ril-daemon` restarts. MPSS must stay up. Wi-Fi is QCA6174 PCIe and does not need MPSS.

---

## On-device commands that worked after first boot

```
# VINTF (vendor remount)
rm /vendor/etc/vintf/manifest/android.hardware.vibrator@1.0.xml
rm /vendor/etc/vintf/manifest/android.hardware.health@2.1.xml
rm /vendor/etc/vintf/manifest/android.hardware.power@1.0.xml

# privapp
rm -rf /system/priv-app/LifeTimerService

# Camera icon
pm enable org.lineageos.snap/com.android.camera.CameraLauncher
pm disable org.lineageos.snap/com.android.camera.SetActivitiesCameraReceiver

# Torch test (root)
echo 1 > /sys/class/leds/led:flash_torch/brightness
echo 0 > /sys/class/leds/led:flash_torch/brightness
```

Restart `hwservicemanager`, `vendor.gralloc-2-0`, `surfaceflinger`, then `stop` / `start` Android.

---

## Reproduce (next zip)

Build host: SteamOS ext4 `/home/deck/android/los-18.1`.

1. Land kernel DT `talkman-camera.dtsi` (`qcom,sensor-name = "mot_imx230"`, no slave-id) in the **built** `Image.gz-dtb`.
2. Keep `manifest.xml` without health / power / vibrator HAL blocks.
3. Do not install LifeTimerService.
4. Lights: write `led:flash_torch` only.
5. `lunch lineage_talkman-userdebug` then `mka bacon`.
6. Copy the zip to the Windows installer PC. Do not `repo sync` onto NTFS.
7. Follow Procedure from step 2 if EFIESP already has LK2ND. Skip mass-storage unlock if already unlocked.
8. Do **not** run stock `partition.sh` if Android GPT already exists.
9. Sideload or `update-binary` the new zip. Capture `out/qa-*`.

---

## GitHub (personal)

Write is **archienz** only.

| Repository | URL |
|---|---|
| Device tree | https://github.com/archienz/android_device_msft_talkman |
| Vendor | https://github.com/archienz/android_vendor_msft_talkman |
| This procedure | `docs/INSTALL.md` on branch `lineage-18.1-talkman-hw` |

Do not open pull requests on Android4Lumia950 unless the owner asks.

Do not publish:

- The ROM zip
- Schematic PDF / schematic-png
- Factory MAC / serial as a public table
- Kernel tree to an archienz remote (no archienz kernel remote)

### Update the GitHub repository page

The repository home page is the README. GitHub Pages for this port is the same repository `docs/` folder.

1. Edit `README.md` Progress and Changes.
2. Edit `docs/INSTALL.md` if the procedure changes.
3. Commit as **archienz** (`archienz@users.noreply.github.com`).
4. `git push archienz lineage-18.1-talkman-hw`.
5. Confirm https://github.com/archienz/android_device_msft_talkman shows the new README.
6. If Pages is on: Settings → Pages → source branch `lineage-18.1-talkman-hw` folder `/docs`. Open `docs/index.md`.

Do not push this text to `Android4Lumia950/Android4Lumia950.github.io`. That site is community. This install is personal.

---

## Git author mistake (apology)

Some older commits show **EpicLPer**. EpicLPer did not write them. **archienz** did. New commits use archienz.
