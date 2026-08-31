# LineageOS 18.1 for Lumia 950 (talkman)

This repository is the **personal** device tree for Microsoft Lumia 950 (`talkman`, RM-1104 / RM-1105 / RM-1108).

The SoC is **MSM8992**. The kernel family is CAF 3.10 (`kernel/mmo/msm8994`).

This is **not** an official LineageOS product. The telephone did not ship with Android.

Vocabulary in this file follows **ASD-STE100** Simplified Technical English (Issue 9) style.
Vocabulary was checked against known rulings and high-risk patterns only, not against the official ASD-STE100 Part 2 dictionary.
Full compliance needs a check against the official standard.

---

## Purpose

This tree makes LineageOS 18.1 (Android 11) run on talkman hardware.

Track A is the daily-driver path: CAF 3.10 kernel plus this device tree.

Track B is a later mainline path. Track B is not this repository.

Priority work (P0):

1. Battery UI
2. Charge (cable and Qi)
3. GPS
4. Camera (rear IMX230)

Cellular / RIL is **P2**. Do not stop P0 for modem SMD errors.

---

## Owner and remotes

| Item | Value |
|---|---|
| Personal GitHub | [archienz/android_device_msft_talkman](https://github.com/archienz/android_device_msft_talkman) (**private**) |
| Branch | `lineage-18.1-talkman` |
| Community source | [Android4Lumia950/android_device_msft_talkman](https://github.com/Android4Lumia950/android_device_msft_talkman) |
| Lunch target | `lineage_talkman-userdebug` (use `lunch`, not `breakfast`) |

Push personal work to **archienz**. Do not open pull requests on the community organization unless the owner asks.

---

## Hardware (technical nouns)

| Name | Fact |
|---|---|
| Device | Lumia 950, `talkman` |
| SoC | MSM8992 (4× Cortex-A53 + 2× Cortex-A57) |
| GPU | Adreno 418 |
| PMIC | PM8994 + PMI8994 |
| Battery pack | BV-T5E, 3000 mAh |
| Rear camera | Sony IMX230 (DCC 104541, chip 0x0230) |
| Front camera | SMIApp, name not known |
| OIS | Mitsumi bu24210 (DCC `.kar` MCU image) |
| Speaker | TAS2553 on QUAT_MI2S |
| NFC | NXP PN547 |
| WLAN | QCA6174 |
| USB-C | HD3SS460 + iCE5LP2K. No USB Power Delivery |

CCI 7-bit slave IDs are **not** in this tree. Do not invent `qcom,slave-id`.

---

## Progress (2026-08-31)

**Definition of done:** a physical talkman log in `out/qa-*`. Source in Git is not a pass.

No P0 item is **Working**.

| ID | Subsystem | Status | What is in source | What is still missing |
|---|---|---|---|---|
| P0.0 | Rebuild LOS 18.1 | Not done | Manifest and `README-BUILD.md` | WSL Ubuntu 22.04, 250–400 GB ext4, `mka bacon` |
| P0.1 | Battery UI | Not Working | Fuel-gauge OCV+CC if pack ID does not match. Overlay capacity 3000 mAh. Warning levels 15 / 5. No hardcoded 50% | `dumpsys battery` and USB-meter log on the telephone |
| P0.2 | Charge | Not Working | Driver sets cable 1800 mA and Qi 900 mA. No PD. No HVDCP | USB-meter proof that SoC increases |
| P0.3 | GPS | Not Working | GNSS HIDL `impl.talkman`. SUPL 2.0. NTP `pool.ntp.org`. 0-SV locations are dropped | GPSTest log with `numSvs` more than 0 |
| P0.4 | Camera | Not Working | DT name `mot_imx230`. XML CameraId 0. Clark 32-bit sensor libraries. Flash/torch PMI nodes | CCI scan on the telephone, JPEG still, OIS `.so` |
| P2 | RIL | Deferred | Research notes only | Modem SMD |

---

## Changes in this tree (summary)

Do this list as a description of files, not as a procedure.

### Battery and charge

- `power_profile.xml` uses battery capacity **3000** (BV-T5E). The bullhead value 2700 is not used.
- Overlay warning levels are 15 percent and 5 percent.
- Dumpstate reads `battery`, `bms`, `usb`, and `dc`. Dumpstate does not write CCI scan.

Kernel fuel-gauge and charger drivers live in `android_kernel_mmo_msm8994`, not in this repository.

### GPS

- Package `android.hardware.gnss@1.0-impl.talkman`.
- NMEA callback copies data to an owned buffer. CAF length must not go to HIDL `setToExternal` (that path caused SIGABRT).
- Locations with 0 satellites or position (0,0) are dropped.
- SUPL uses `wlan0`. The tree does not send IMSI.

### Camera

- XML `SensorName` is `mot_imx230` for CameraId 0.
- There is no CameraId 1. Front sensor name is not known.
- `BOARD_QTI_CAMERA_32BIT_ONLY` is true. `USE_CAMERA_STUB` is false.
- Media profiles: rear 3840×2160 at 30 fps, H.264. No HEVC encode. No 4K60.
- OIS `.kar` files can be in vendor firmware. There is no `libmmcamera_ois_bu24210.so` in the dumps. Do not make a stub library.

### Display and lights

- Duke AMOLED is command-mode. Always-on display is false.
- Light HIDL 2.0 writes lcd-backlight and RGB sysfs.

### Other

- NFC node is `/dev/pn547`. Firmware matches WOA `nxppn547fw.dat`.
- Wi-Fi MAC comes from factory DPP. The image does not contain a MAC address.
- TWRP kernel path is `kernel/mmo/msm8994`.
- SELinux stays permissive for bring-up.

---

## What you must not do

- Do not invent a CCI slave ID.
- Do not mark P0 Working without `out/qa-*` logs from the telephone.
- Do not return a fake battery capacity of 50 percent.
- Do not count a black camera buffer as success.
- Do not enable USB Power Delivery in the UI. The hardware has no PD.

---

## How to build (procedure)

If you do not have WSL Ubuntu 22.04 and 250 GB or more of ext4, stop.

1. Install WSL Ubuntu 22.04.
2. Clone LineageOS 18.1 with the talkman local manifest.
3. Put this tree at `device/msft/talkman`.
4. Put the kernel at `kernel/mmo/msm8994`.
5. Put vendor at `vendor/msft/talkman` (branch `lineage-18.1-julian`).
6. Run `source build/envsetup.sh`.
7. Run `lunch lineage_talkman-userdebug`.
8. Run `mka bacon`.

Do a check of `docs/QA-CHECKLIST.md` after the first boot.

---

## Related personal repositories

| Repository | Role |
|---|---|
| [archienz/android_device_msft_talkman](https://github.com/archienz/android_device_msft_talkman) | This device tree |
| [archienz/android_vendor_msft_talkman](https://github.com/archienz/android_vendor_msft_talkman) | Vendor copy files |

Kernel work stays on the local tree until a personal kernel repository exists.

Workspace notes on the build host: `C:\users\Archie\desktop\phone\docs\`.
