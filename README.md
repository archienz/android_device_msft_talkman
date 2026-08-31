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
| Personal GitHub | [archienz/android_device_msft_talkman](https://github.com/archienz/android_device_msft_talkman) (**public**) |
| Branch | `lineage-18.1-talkman-hw` |
| Write access | **archienz** only |
| Community source | [Android4Lumia950/android_device_msft_talkman](https://github.com/Android4Lumia950/android_device_msft_talkman) |
| Lunch target | `lineage_talkman-userdebug` (use `lunch`, not `breakfast`) |

Push personal work to **archienz**. Do not open pull requests on the community organization unless the owner asks.

---

## Hardware (technical nouns)

| Name | Fact |
|---|---|
| Device | Lumia 950, `talkman` |
| Schematic | RM-1104 board **4VM_08r** only. Dual SIM RM-1118 / **4VM_08d** is not this product |
| SoC | MSM8992 (4× Cortex-A53 + 2× Cortex-A57) |
| GPU | Adreno 418 |
| PMIC | PM8994 + PMI8994 |
| Battery pack | BV-T5E, 3000 mAh |
| Rear camera | Sony IMX230 (DCC 104541, chip 0x0230 on paper). First SMIA `0x0016` decides IMX230 vs IMX278 |
| Front camera | SMIApp, name not known. EpicLPer dump `0x2140` is a lab note, not our scan |
| OIS | Mitsumi bu24210 (DCC `.kar` MCU image). No `libmmcamera_ois_bu24210.so` |
| Speaker | TAS2553 on QUAT_MI2S. PGA default **0x12** (11 dB) |
| NFC | NXP PN547 `/dev/pn547`. Kernel `nq-nci`: 250 ms I2C timeout, no `read_mutex` across IRQ, VEN without eSE |
| WLAN | QCA6174 |
| USB-C | HD3SS460 + iCE5LP2K. No USB Power Delivery |
| Side keys | FOCUS GPIO 5, SHOT GPIO 4, VOL_UP GPIO 3. Power and volume-down are PON |

CCI 7-bit slave IDs are **not** in this tree. Do not invent `qcom,slave-id`.

Rear camera I2C is **CCI master 1** (RM-1104 schematic 4VM_08r page 2, plus EpicLPer lab). Front and iris stay on CCI0. CCI1 pinctrl is GPIO 19 / 20 on `&cci`.

LVS1 is always-on. LVS1 is not a camera vreg.

Side keys FOCUS / SHOT / VOL_UP match 4VM_08r (PM8994 GPIO 5 / 4 / 3).

NFC GPIOs match DT: IRQ 29, VEN 30, DWL 94. Schematic OCR was wrong.

Schematic PDF pages are rendered as PNG in workspace `docs/hardware/schematic-png/`. Notes: `docs/hardware/SCHEMATIC-RM-1104.md`. Dual SIM RM-1118 / **4VM_08d** is ignored.

Hill ident candidates **0x20** / **0x7c** / **0x22** are lab notes in `CAMERA-IDENT.md`. They are not DT.

Iris `qcom,camera@2` is **disabled** (CSI2 / CCI0 GPIO 14 / 102). No iris slave-id. No XML CameraId for iris.

Qi GPIOs match 4VM_08r: `wc-en` GPIO **2**, `wc-det` GPIO **14**.

---

## Progress (2026-08-31)

Wave 19 **DONE** (source only, not a meter pass). Keep Wave 18 README `6871f51`. Keep Wave 16 README `3c14b94`. Keep `1d143f5`. Do not restore `abeb48a`. VINTF leftover `55b29f2` stays **LIVE** on `manifest.xml`. Do not steal that leftover.

**Definition of done:** a physical talkman log in `out/qa-*`. Source in Git is not a pass. There is no LOS zip. There is no `out/qa-*` meter log. CCI scan never ran on the telephone. GPSTest never ran.

No P0 item is **Working**. Mixer speaker is QUAT_MI2S (`66c7d50`). `extract-files.sh` dests match COPY_FILES (`6e4d4c2`) for 32-bit `mot_imx230` and bu24210 `.kar`. Lineage fingerprint is `Microsoft/talkman` (`44cb3c5`). Settings overlay leftover (`2fca2c7`: no `color_temp`, no Bell IPv4, no FPC). WCNSS QCA6174 `gNumRxAnt=2`. Location sepolicy `0c0a081`. USB `g_android` (`93506aa`). `androidboot.usbconfigfs=0` (`5d03a73`). Thermal HAL `thermal.talkman` (`9b6cd42` vendor julian). `privapp-permissions` dropped LGE (`ca9adee`). NFC GPIOs match schematic PNG crop (IRQ 29, VEN 30, DWL 94). Rear camera is CCI1 (bus, not SID). LVS1 is always-on, not a cam vreg. `ueventd` jpeg0/jpeg3 (`e9b365a`). CAMERA-IDENT CCI1 (`63bed4c`). Dual SIM RM-1118 / 4VM_08d is not this product. No `qcom,slave-id`.

Wave 19 source (not a pass): lights HIDL torch on `led:flash_torch` and `led:torch_0` (`d92e6c3`; no leftover `led::flash_torch`). QCA6174 `hostapd` / `wpa` overlays (`e4b23cf`: WPA2-PSK 11n, no SAE / 6 GHz / VHT AP). Overlay wifi leftover (`004a8fb`: QCA6174, no LGE strings). lineage-sdk overlay leftover (`ef27b11`: no prox-on-wake, no `color_temp` LiveDisplay, no FPC). `libpn547_fw.so` installs at HAL path `/system/vendor/firmware` (`749c1c0`). PN547 download image is WOA `nxppn547fw.dat`; Sony 8.1 dump is leftover. Kernel GPIO12 (`3068a345c0e`) and FG 3200/3500 (`91c0c0317c3`) live in `android_kernel_mmo_msm8994`. Installer packed `modem.img` (`dc847d5`).

Wave 18 source (not a pass): `bluetooth/bt_vendor.conf` QCA6174 leftover (`988ad95`: persist/OTP, `USE_CONTROLLER_BDADDR=TRUE`, no sample MAC). Dumpstate lists torch/flash LED sysfs and `/dev/video*` (`bf43f49`; no open, no CCI write). Vendor `sap.conf` (`e65e4b2`) NDK names ICM-206xx / AK09912 / ZPA2326, `SENSOR_PROVIDER=2`. MATCH: TWRP `mmo_defconfig`, `media_profiles` IMX230 4K30 H.264, `audio_platform_info` QUAT_MI2S, NFC sepolicy PN547 `/dev/pn547`, kernel `msm8992-chi.dtsi` includes `talkman-camera.dtsi`, `powerhint.xml` MSM8992, lk2nd board-id `0x1a` (`<26 0>`; not CCI `0x19`), `gps.conf` committed (`PRODUCT_COPY_FILES` system+vendor). Workspace `tools/cci_scan/Android.mk` installs `/system/bin/cci_scan` (`TARGET_OUT_EXECUTABLES`). No extra forks.

Wave 16 source (not a pass): iris `qcom,camera@2` disabled (CSI2 / CCI0 GPIO 14 / 102, no slave-id); Qi GPIOs match; CAMERA-IDENT CCI1 is bus not slave-id; Fluence is mic AEC; `usbconfigfs=0`; ueventd jpeg0/jpeg3; camera sepolicy already vendor lib+XML. Wave 15 still in tree: mixer QUAT (`66c7d50`), WCNSS 2×2, g_android, thermal, extract `6e4d4c2`.

Host blockers: no WSL Ubuntu 22.04. About 23 GB free on C:. CCI scan never ran. No GPSTest log.

| ID | Subsystem | Status | What is in source | What is still missing |
|---|---|---|---|---|
| P0.0 | Rebuild LOS 18.1 | Not done | Manifest and `README-BUILD.md` | WSL Ubuntu 22.04, 250–400 GB ext4, `mka bacon` |
| P0.1 | Battery UI | Not Working | Fuel-gauge OCV+CC if pack ID does not match. Overlay capacity 3000 mAh. Kernel FG 3200/3500 (`91c0c0317c3`). Warning levels 15 / 5. Settings health reads `bms/charge_full*`. Dumpstate walks psy. No hardcoded 50% | `dumpsys battery` and USB-meter log on the telephone |
| P0.2 | Charge | Not Working | Kernel driver sets cable 1800 mA and Qi 900 mA. Overlay strings say 5 V 1.8 A and Qi 900 mA. USB-C mux driver `mmo-usbc.c`. Kernel GPIO12 (`3068a345c0e`). No PD. No HVDCP | USB-meter proof that SoC increases |
| P0.3 | GPS | Not Working | GNSS HIDL `impl.talkman`. SUPL 2.0. NTP `pool.ntp.org`. Packed installer `modem.img` (`dc847d5`) 70 MiB with MBA/MPSS. 0-SV locations are dropped | GPSTest log with `numSvs` more than 0 |
| P0.4 | Camera | Not Working | DT name `mot_imx230`. XML CameraId 0. Clark 32-bit sensor libraries. Flash/torch PMI nodes. HAL1 props. LVS1 always-on, not a cam vreg. `cam_vio` is not in rear/front `qcom,cam-vreg-name`. Iris `camera@2` disabled. OIS `.kar` in COPY_FILES; `msm_ois` does not `request_firmware` | CCI scan on the telephone, JPEG still, OIS `.so` |
| P2 | RIL | Deferred | Research notes only | Modem SMD |

Keep QCamera2 MSMB `mot_imx230`. EpicLPer HAL1 “preview” is CSID test-generator, not live CSI. Do not ship TG.

---

## Changes in this tree (summary)

Do this list as a description of files, not as a procedure.

### Battery and charge

- `power_profile.xml` uses battery capacity **3000** (BV-T5E). The bullhead value 2700 is not used.
- Overlay warning levels are 15 percent and 5 percent.
- Charge UI strings are 5 V 1.8 A and Qi 900 mA. The UI does not say PD or Quick Charge. Qi `wc-en` GPIO 2 and `wc-det` GPIO 14 match 4VM_08r.
- Settings Battery Health reads `bms/charge_full`, `charge_full_design`, and `cycle_count`.
- Dumpstate reads `battery`, `bms`, `usb`, and `dc`. Dumpstate lists torch/flash LED sysfs and `/dev/video*` (`bf43f49`). Dumpstate does not write CCI scan.
- `sepolicy/dumpstate.te` lets `dumpstate` read `sysfs_batteryinfo`. SELinux stays permissive.

Kernel fuel-gauge and charger drivers live in `android_kernel_mmo_msm8994`, not in this repository.

### GPS

- Package `android.hardware.gnss@1.0-impl.talkman`.
- NMEA callback copies data to an owned buffer. CAF length must not go to HIDL `setToExternal` (that path caused SIGABRT).
- Locations with 0 satellites or position (0,0) are dropped.
- SUPL uses `wlan0`. The tree does not send IMSI.
- `sepolicy/gps_conf.te` and `location.te` let `location` (`loc_launcher`) and `hal_gnss_default` search `vendor_configs_file` and read `gps_conf_file`. SELinux stays permissive. No IMSI. No rild.
- `gps.conf` is in this tree (`gps/gps.conf` copied to system and vendor).
- Vendor `sap.conf` (`e65e4b2`) uses NDK names ICM-206xx Accelerometer / Gyroscope, AK09912 Magnetometer, ZPA2326 Pressure / Temperature. `SENSOR_PROVIDER=2`. Not nanohub. Not SSC.

### Camera

- XML `SensorName` is `mot_imx230` for CameraId 0.
- There is no CameraId 1. Front sensor name is not known. Iris `qcom,camera@2` is disabled. No iris XML.
- CAMERA-IDENT: CCI master 1 is a bus index. It is not `qcom,slave-id`.
- `BOARD_QTI_CAMERA_32BIT_ONLY` is true. `USE_CAMERA_STUB` is false.
- `system.prop` and `vendor.prop` force HAL1: `persist.camera.HAL3.enabled=0`. `vendor.prop` also sets IS type 4, TNR off, EIS enable (unused while HAL3 is off).
- Media profiles: rear 3840×2160 at 30 fps, H.264 (IMX230). No HEVC encode. No 4K60.
- Kernel DT `msm8992-chi.dtsi` includes `talkman-camera.dtsi`.
- LVS1 is always-on. `cam_vio` is not in rear or front cam-vreg / power-seq.
- OIS `.kar` files are in COPY_FILES (`6e4d4c2`). CAF `msm_ois` does not `request_firmware` those `.kar` files. There is no `libmmcamera_ois_bu24210.so` in the dumps. Do not make a stub library.

### Display and lights

- Duke AMOLED is command-mode. Always-on display is false.
- Light HIDL 2.0 writes lcd-backlight and RGB sysfs. Torch writes `led:flash_torch` and `led:torch_0` (`d92e6c3`). There is no leftover `led::flash_torch`.

### Other

- NFC node is `/dev/pn547`. Firmware matches WOA `nxppn547fw.dat`. Sony 8.1 dump is leftover. `libpn547_fw.so` path is `/system/vendor/firmware` (`749c1c0`). Kernel `nq-nci` already has 250 ms timeout and VEN without eSE. GPIOs match schematic PNG crop: IRQ 29, VEN 30, DWL 94. `sepolicy/nfc.te` is PN547 (no FeliCa).
- `bluetooth/bt_vendor.conf` is QCA6174 leftover (`988ad95`): UART `/dev/ttyHS0`, `USE_CONTROLLER_BDADDR=TRUE`. BD_ADDR is persist `/persist/bdaddr.txt` or QCA OTP. No sample MAC in this file.
- TWRP and `BoardConfig` use `TARGET_KERNEL_CONFIG := mmo_defconfig`.
- `audio_platform_info.xml` is QUAT_MI2S (TAS2553).
- `configs/powerhint.xml` is MSM8992 (`platform="msm8992"`, A57 ceiling 1824000 kHz).
- Frameworks overlay is `overlay/frameworks/base/core/res/res/values/config.xml`.
- lineage-sdk overlay leftover (`ef27b11`): no prox-on-wake, no `color_temp` LiveDisplay, no FPC.
- Wi-Fi overlay leftover (`004a8fb`): QCA6174, no LGE strings. `hostapd` / `wpa` overlays (`e4b23cf`) stay WPA2-PSK 11n.
- Vendor COPY_FILES has no IMX377.
- lk2nd talkman DTS: `qcom,board-id = <26 0>` and `qcom,msm-id` `0x0001001a`. That is not a CCI slave-id.
- Workspace `tools/cci_scan/Android.mk` builds `/system/bin/cci_scan`. The binary does not contain slave addresses.
- Lineage `BUILD_FINGERPRINT` is `Microsoft/talkman/talkman:11/RQ3A.211001.001/1:user/release-keys` (`44cb3c5`).
- Settings overlay leftover (`2fca2c7`): no `color_temp`, no Bell IPv4, no FPC.
- `init.talkman.rc` imports camera/nfc/gps. There is no duplicate `qcamerasvr` start. There is no CCI echo.
- Tethering hotspot provision arrays are empty (no LGE entitlement URL). `privapp-permissions-talkman.xml` dropped `com.lge.entitlement`.
- Mixer speaker path is QUAT_MI2S (TAS2553). WCD SPK DRV is not wired.
- `extract-files.sh` dests match COPY_FILES. 32-bit `mot_imx230` and bu24210 `.kar` only. Banned dests: IMX377, OV5693, nanohub, OMADM, LGE entitlement, LifeTimer.
- WCNSS `wifi/WCNSS_qcom_cfg.ini` is QCA6174 2×2 (`gEnable2x2=1`, `gNumRxAnt=2`). No 11ax, no 6 GHz, no WPA3/SAE ini keys. MAC is not in this ini.
- `init.talkman.usb.rc` is `g_android` sysfs. `sys.usb.configfs=0`. `BoardConfig` `androidboot.usbconfigfs=0`. No `/config/usb_gadget`. Default `persist.sys.usb.config=adb`.
- Thermal HAL package is `thermal.talkman` (`thermal/thermal.c`, vendor partition). Not a P0 meter pass.
- Fluence UUIDs in `audio_effects.xml` are mic AEC/NS. They are not the TAS speaker path.
- `ueventd.talkman.rc` labels jpeg0 / jpeg3, video/media, flash_0/1 torch_0/1 flash_torch, pn547. No jpeg1/jpeg2.
- Camera sepolicy already covers vendor lib + XML. Init does not write CCI scan. SELinux stays permissive.
- Wi-Fi MAC comes from factory DPP. The image does not contain a MAC address.
- Sensors HAL is `sensors.talkman.so`. No BMI160. No nanohub. SAP names match ICM-206xx / AK09912 / ZPA2326.
- Speaker volume curves are AOSP defaults for TAS2553. Bullhead WCD DRC curves are gone. TAS PGA default is **11 dB**.
- TWRP kernel path is `kernel/mmo/msm8994`. TWRP config is `mmo_defconfig`.
- OTA assert is `talkman` only (no bullhead, no angler).
- SELinux stays permissive for bring-up.
- Protected Wi-Fi Display buffers are off.

---

## What you must not do

- Do not invent a CCI slave ID.
- Do not mark P0 Working without `out/qa-*` logs from the telephone.
- Do not return a fake battery capacity of 50 percent.
- Do not count a black camera buffer as success.
- Do not enable USB Power Delivery in the UI. The hardware has no PD.
- Do not ship CSID test-generator as camera.
- Do not Magisk-bind a random `imx230` HAL.
- Do not use Dual SIM RM-1118 / board 4VM_08d as talkman schematic.

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
