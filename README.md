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

Do not mark P0 Working without `out/qa-*` logs from the telephone. Do not invent `qcom,slave-id`. Dual SIM RM-1118 is not this product.

---

## Owner and remotes

| Item | Value |
|---|---|
| Personal GitHub | [archienz/android_device_msft_talkman](https://github.com/archienz/android_device_msft_talkman) (**public**) |
| Branch | `lineage-18.1-talkman-hw` |
| Write access | **archienz** only |
| Community source | [Android4Lumia950/android_device_msft_talkman](https://github.com/Android4Lumia950/android_device_msft_talkman) |
| Lunch target | `lineage_talkman-userdebug` (use `lunch`, not `breakfast`) |
| Install procedure | [`docs/INSTALL.md`](docs/INSTALL.md) |
| GitHub Pages | https://archienz.github.io/android_device_msft_talkman/ (`docs/` on this branch) |
| Pages install | https://archienz.github.io/android_device_msft_talkman/INSTALL.html |

Push personal work to **archienz**. Do not open pull requests on the community organization unless the owner asks. Do not push to `Android4Lumia950/Android4Lumia950.github.io`.

### Git author mistake (apology)

Some commits on `lineage-18.1-talkman-hw` show the GitHub user **EpicLPer**. EpicLPer did **not** write those commits. The owner **archienz** did. The automated assistant (Grok) is at fault.

The local git `user.name` / `user.email` on this clone was set to EpicLPer’s identity. Git copies those two strings into every commit. The push used **archienz** credentials. GitHub then attached the commits to EpicLPer because the email matched.

That is a configuration error. It is not EpicLPer’s work. It is not a fork of EpicLPer’s camera notes as a drop-in tree. Sorry.

The local git user on this repository is now **archienz**. New commits use `archienz@users.noreply.github.com`. Old commit objects still contain the wrong author until history is rewritten. This branch does not force-push.

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

Rear camera I2C is **CCI master 1** (RM-1104 4VM_08r plus EpicLPer lab). Front and iris stay on CCI0. CCI1 pinctrl is GPIO 19 / 20 on `&cci`.

LVS1 is always-on. LVS1 is not a camera vreg.

Side keys FOCUS / SHOT / VOL_UP match 4VM_08r (PM8994 GPIO 5 / 4 / 3).

NFC GPIOs match DT: IRQ 29, VEN 30, DWL 94.

Dual SIM RM-1118 / **4VM_08d** is ignored. The Microsoft service schematic is for implementation only. It is **not** published.

Hill ident candidates **0x20** / **0x7c** / **0x22** are lab notes in `CAMERA-IDENT.md`. They are not DT.

Iris `qcom,camera@2` is **disabled** (CSI2 / CCI0 GPIO 14 / 102). No iris slave-id. No XML CameraId for iris.

Qi GPIOs match 4VM_08r: `wc-en` GPIO **2**, `wc-det` GPIO **14**.

---

## Progress (2026-09-02)

Source in Git is not a pass. A pass is a physical talkman log in `out/qa-*`.

Unofficial zip `lineage-18.1-20260901-UNOFFICIAL-talkman` is installed on one RM-1104. The telephone boots to the home screen. Procedure (steps that worked, failures, reproduce, Pages update): [`docs/INSTALL.md`](docs/INSTALL.md) and https://archienz.github.io/android_device_msft_talkman/INSTALL.html. Capture: workspace `out/qa-pre-steamos-20260902/` (not in Git).

Host: Steam Deck SteamOS, ext4 `/home/deck/android/los-18.1`. Do not `repo sync` onto NTFS.

No P0 item is **Working**. Dual SIM RM-1118 is not this product. There is no `qcom,slave-id`. There is no `CONFIG_MSM_OIS`. CCI scan never ran (flashed DTB has no scan node).

The Microsoft service schematic is for implementation only. It is not published.

| ID | Subsystem | Status | What is on the telephone | What is still missing |
|---|---|---|---|---|
| P0.0 | Rebuild LOS 18.1 | Built and flashed | `lineage_talkman-userdebug` zip 2026-09-01. SteamOS ext4 `/home/deck/android/los-18.1` | Next bacon with camera DT + VINTF + no LifeTimer |
| P0.1 | Battery UI | Not Working | `dumpsys battery` 66 percent, 4.030 V, 41 °C, Li-ion. Not 50 percent | USB-meter log |
| P0.2 | Charge | Not Working | USB powered, ~500 mA in the log. No PD | USB-meter proof that SoC increases |
| P0.3 | GPS | Not Working | GPSTest installed. `loc_eng_start`. 0 satellites. `ril-daemon` restarts | `numSvs` more than 0. MPSS online |
| P0.4 | Camera | Not Working | Daemon now probes **`mot_imx230`** only (was imx377). `msm_sensor_match_id: mot_imx230: read id failed`, CCI MASTER_1 no ACK. 0 devices. GPIO torch works | CCI ACK of Sony `0x0230` on the bus `qcom,camera@0` uses, then JPEG |
| — | Display / Wi-Fi / speaker | On this telephone | 1440×2560. QCA6174 factory MAC. Loudspeaker `STREAM_MUSIC` | Not P0 |
| P2 | RIL | Deferred | `ril-daemon` exit 1 | Modem SMD |

Keep QCamera2 MSMB `mot_imx230`. EpicLPer HAL1 “preview” is CSID test-generator, not live CSI. Do not ship TG.

---

## Changes

This section is a description of the tree. It is not a procedure.

### Install and first boot (2026-09-02)

- Procedure: [`docs/INSTALL.md`](docs/INSTALL.md). Pages: https://archienz.github.io/android_device_msft_talkman/INSTALL.html. How to update Pages is in that file.
- `manifest.xml` does not list health 2.1, power 1.0, or vibrator 1.0. Those HALs ship `vintf_fragments`. A duplicate list made `hwservicemanager` reject the device manifest (`HAL vibrator has a conflict`). SurfaceFlinger then aborted `gralloc-mapper is missing` (black screen).
- Do not package `LifeTimerService`. The APK is a bullhead leftover. PackageManager whitelist crash loops `system_server`.
- Snap `CameraLauncher` is disabled when the HAL has 0 cameras. That hides the icon. The crash is `PhotoModule.initializeFocusManager` index 0 on an empty list.
- Lights HIDL must write **only** `led:flash_torch` (GPIO 12). A write to `led:torch_0` can light the red indicator. The QS tile uses CameraManager, not this sysfs.
- The daemon probed **imx377** while the XML said `mot_imx230` because
  `sensor_init_probe()` in `libmmcamera2_sensor_modules.so` does not read the XML.
  It walks a sensor list compiled into that blob (`imx214`, `imx230`, `s5k3m2xx`,
  `imx377`, `s5k3m2xm`, `ov4688`, `imx258`, `ov5693`) and opens
  `vendor/lib/libmmcamera_<name>.so` for each. Only `libmmcamera_imx377.so` and
  `libmmcamera_ov5693.so` were on the image, so only those two probed, and
  `libmmcamera_mot_imx230.so` was never opened. The XML is read later, to match a
  sensor the kernel already accepted.
- Fix: drop the two bullhead sensor libraries and install the Clark library a
  second time as `libmmcamera_imx230.so`. The probe name comes from the file name,
  but the name that goes to the kernel comes from `sensor_slave_info` in the
  library, so the `imx230` slot probes as `mot_imx230`. Measured on the telephone
  2026-09-02: one probe, `msm_sensor_match_id: mot_imx230`, no imx377 and no ov5693.
- `/data/sensor/<name>/libmmcamera_<name>.so` is an external-sensor path in the
  same blob. It is a diagnostic only. Do not ship it: `/data` is late and the
  camera domain has no policy for it.

### Battery and charge

- `power_profile.xml` uses battery capacity **3000** (BV-T5E). The bullhead value 2700 is not used.
- Overlay warning levels are 15 percent and 5 percent.
- Charge UI strings are 5 V 1.8 A and Qi 900 mA. The UI does not say PD or Quick Charge. Qi `wc-en` GPIO 2 and `wc-det` GPIO 14 match 4VM_08r.
- Settings Battery Health reads `bms/charge_full`, `charge_full_design`, and `cycle_count`.
- Health is `android.hardware.health@2.1-impl.talkman` (`health/HealthImpl.cpp`). It pins `bms/charge_full`, `charge_full_design`, `cycle_count`, and energy from `bms/charge_now` × `voltage_now`. Capacity still comes from `battery` (smbcharger proxy). No hardcoded 50%.
- Overlay `config_chargingFastThreshold` is 15 W. Charge UI does not say Fast Charge or PD.
- Dumpstate reads `battery`, `bms`, `usb`, and `dc`. Dumpstate lists torch/flash LED sysfs and `/dev/video*` (`bf43f49`). Dumpstate `getattr` on torch LED sysfs. Dumpstate does not write CCI scan.
- `sepolicy/dumpstate.te` lets `dumpstate` read `sysfs_batteryinfo`. SELinux stays permissive.

Kernel fuel-gauge and charger drivers live in `android_kernel_mmo_msm8994`, not in this repository.

### GPS

- CAF loc modules (`libgps.utils`, `libloc_core`, `libloc_eng`, `gps.msm8992`) install to vendor. `libloc_api_v02` / `libloc_ds_api` copy to `/vendor/lib*`.
- `init.talkman.gps.rc` chmods `izat.conf`, `sap.conf`, `flp.conf`, `lowi.conf` under `/system/etc` (the path the blobs open).
- Package `android.hardware.gnss@1.0-impl.talkman`.
- NMEA callback copies data to an owned buffer. CAF length must not go to HIDL `setToExternal` (that path caused SIGABRT).
- Locations with 0 satellites or position (0,0) are dropped.
- SUPL uses `wlan0`. The tree does not send IMSI.
- `sepolicy/gps_conf.te` and `location.te` let `location` (`loc_launcher`) and `hal_gnss_default` search `vendor_configs_file` and read `gps_conf_file`. They also read `izat.conf`, `sap.conf`, `flp.conf`, and `lowi.conf` as `vendor_configs_file`. SELinux stays permissive. No IMSI. No rild.
- `gps.conf` is in this tree (`gps/gps.conf` copied to system and vendor).
- Framework overlay `config_gpsParameters` matches that file: SUPL 2.0 MSB, NTP `pool.ntp.org`, XTRA `xtra3grc.bin`. There is no `GPS_LOCK`. There is no MSA.
- Vendor `sap.conf` (`e65e4b2`) uses NDK names ICM-206xx Accelerometer / Gyroscope, AK09912 Magnetometer, ZPA2326 Pressure / Temperature. `SENSOR_PROVIDER=2`. Not nanohub. Not SSC.

### Camera

- XML `SensorName` is `mot_imx230` for CameraId 0.
- Snap overlay is CameraId 0 `mot_imx230` HAL1. `support_camera_api_v2` is false. There is no Dual SIM CameraId 1.
- There is no CameraId 1. Front sensor name is not known. Iris `qcom,camera@2` is disabled. No iris XML.
- CAMERA-IDENT: CCI master 1 is a bus index. It is not `qcom,slave-id`.
- `BOARD_QTI_CAMERA_32BIT_ONLY` is true. `USE_CAMERA_STUB` is false.
- `system.prop` and `vendor.prop` force HAL1: `persist.camera.HAL3.enabled=0`. `vendor.prop` also sets IS type 4, TNR off, EIS enable (unused while HAL3 is off).
- Media profiles: rear 3840×2160 at 30 fps, H.264 (IMX230). No HEVC encode. No 4K60.
- Kernel DT `msm8992-chi.dtsi` includes `talkman-camera.dtsi`, `wlan.dtsi`, `leds.dtsi`, `thermal.dtsi`, `usbc.dtsi`, and `pil.dtsi`.
- LVS1 is always-on. `cam_vio` is not in rear or front cam-vreg / power-seq.
- OIS `.kar` files are in COPY_FILES (`6e4d4c2`). CAF `msm_ois` does not `request_firmware` those `.kar` files. There is no `libmmcamera_ois_bu24210.so` in the dumps. Do not make a stub library.

### Display and lights

- Duke AMOLED is command-mode. LAB/IBB mode is amoled at 4.6 V. Always-on display is false. Pickup pulse is false.
- Recents is SystemUI `OverviewProxyRecentsImpl` on the software 3-button navbar. There is no capacitive APP_SWITCH.
- Overlay `config_deviceHardwareKeys` is 96 (CAMERA plus VOLUME). Wake keys are the same. There is no APP_SWITCH key.
- Light HIDL 2.0 writes lcd-backlight and RGB sysfs. Torch writes `led:flash_torch` and `led:torch_0` (`d92e6c3`). Torch GPIO is **12**. HIDL 2.0 has no `Type::FLASHLIGHT` enum; torch stays on the liblight `LIGHT_ID_FLASHLIGHT` path and `QCameraFlash` GPIO LED backend. Kernel `flash.dtsi` is PMI8994 qpnp-flash-led with that GPIO. sepolicy `hal_light` sysfs_leds matches those names (`6a8f621`). There is no leftover `led::flash_torch`.
- Rear torch is MSM GPIO 12 into flash driver IC N1400 TORCH pin. I2C address is not on the drawing. There is no `qcom,slave-id`.

### Other

- NFC node is `/dev/pn547`. Firmware matches WOA `nxppn547fw.dat`. Sony 8.1 dump is leftover. `libpn547_fw.so` path is `/system/vendor/firmware` (`749c1c0`). Kernel `nq-nci` already has 250 ms timeout and VEN without eSE. GPIOs: IRQ 29, VEN 30, DWL 94. `sepolicy/nfc.te` is PN547 (no FeliCa).
- `bluetooth/bt_vendor.conf` is QCA6174 leftover (`988ad95`): UART `/dev/ttyHS0`, `USE_CONTROLLER_BDADDR=TRUE`. BD_ADDR is persist `/persist/bdaddr.txt` or QCA OTP. No sample MAC in this file.
- TWRP and `BoardConfig` use `TARGET_KERNEL_CONFIG := mmo_defconfig`.
- `audio_platform_info.xml` is QUAT_MI2S (TAS2553).
- `configs/powerhint.xml` is MSM8992 (`platform="msm8992"`, A57 ceiling 1824000 kHz).
- Frameworks overlay is `overlay/frameworks/base/core/res/res/values/config.xml`.
- lineage-sdk overlay leftover (`ef27b11`): no prox-on-wake, no `color_temp` LiveDisplay, no FPC.
- Wi-Fi overlay leftover (`004a8fb`): QCA6174, no LGE strings. `hostapd` / `wpa` overlays leftover (`81aff9c` MATCH `e4b23cf`) stay WPA2-PSK 11n. No SAE, no 6 GHz AP, no VHT AP.
- Wi-Fi leftover also (`ecf0818`) sets `config_wifi5ghzSupport` true. `config_wifi6ghzSupport` and `config_wifi11axSupportOverride` are false. SAE upgrade and SoftAP SAE are false. Connected, P2P, and AP MAC randomization are false. Spatial streams are 2. There is no generated MAC.
- Wi-Fi leftover also sets `config_wifiSaeUpgradeOffloadEnabled` false, `config_wifi_softap_acs_supported` false, `config_wifi_softap_ieee80211ac_supported` false, `config_wifiSoftapIeee80211axSupported` false, and `config_wifiSoftap6ghzSupported` false. Fast BSS transition and background scan stay true. SoftAP 2 GHz / 5 GHz / 6 GHz channel lists are empty.
- Wi-Fi leftover also sets `config_wifi_revert_country_code_on_cellular_loss` true and `config_wifi_turn_off_during_emergency_call` true. Country is init SKU, not RIL MCC. `config_wifi_tcp_buffers` is 524288,6291456,8291456,524288,6291456,8291456.
- Wi-Fi leftover also sets `config_wifi_batched_scan_supported` true. Idle receive current is 1 mA. Active Rx is 105 mA. Tx is 235 mA. Operating voltage is 3700 mV.
- Overlay leftover also sets tethering upstream types 0 / 1 / 5 / 7 (mobile, Wi-Fi, HIPRI, Bluetooth). `skip_restoring_network_selection` is true. `config_hotswapCapable` is true leftover. That is not Dual SIM. There is no rild.
- Overlay leftover also sets `networkAttributes` for wifi, mobile, MMS, SUPL, DUN, HIPRI, FOTA, IMS, CBS, IA, Bluetooth, ethernet, and mobile_emergency. `radioAttributes` are 1 / 0 / 7 / 9. `config_mobile_tcp_buffers` lists LTE through EVDO sizes. `config_switch_phone_on_voice_reg_state_change` is false. There is no rild. That is not Dual SIM.
- Overlay leftover also sets `config_device_respects_hold_carrier_config` false. Camera leftover sets `config_camera_sound_forced` false. Launch and lift gesture sensor types are **-1**. Double-tap power for camera is true. There is no ToF / LDAF. There is no Dual SIM CameraId.
- Overlay leftover also sets rounded window corners false. Sustained Performance Mode is true. System navigation keys are true. HWC `setColorTransform` is accelerated. Auto power modes are true. Nearby GMS Messages and Discovery are in `config_deviceDisabledComponents`. Wi-Fi Display is true. Protected WFD buffers stay false. SD card accessibility is true.
- Overlay leftover also sets `config_showNavigationBar` true, `config_hasRecents` true, `config_navBarInteractionMode` 0, and `config_swipe_up_gesture_setting_available` true. That is software 3-button. There is no capacitive APP_SWITCH.
- Overlay leftover also sets `config_cellBroadcastAppLinks` true. Intrusive notification LED is true. Default LED color is white. LED on is 1000 ms. LED off is 4000 ms. Intrusive battery LED is true. Multi-color battery LED is true. Safe media volume index is 5.
- Overlay leftover also sets BLE peripheral true. Max scan filters is 1. Max advertisers is 4. Bluetooth operating voltage is 3300 mV. HFP inband ringing is true. Headset jack uses `/dev/input/event` (`config_useDevInputEventForAudioJack`). There is no generated MAC.
- Vendor COPY_FILES has no IMX377 and no OV5693. It also has no
  `libactuator_lc898212xd*.so` and no `brcb032gwz` / `m24c64s` eeprom: those are
  bullhead and no library on this image names them. `libmmcamera_mot_imx230.so`
  asks for `mot_lc898212xd`, and no dump has that actuator, so the XML keeps no
  `ActuatorName`.
- lk2nd talkman DTS: `qcom,board-id = <26 0>` and `qcom,msm-id` `0x0001001a`. That is not a CCI slave-id.
- Workspace `tools/cci_scan/Android.mk` builds `/system/bin/cci_scan`. The binary does not contain slave addresses.
- Lineage `BUILD_FINGERPRINT` is `Microsoft/talkman/talkman:11/RQ3A.211001.001/1:user/release-keys` (`44cb3c5`).
- Settings overlay leftover (`2fca2c7`): no `color_temp`, no Bell IPv4, no FPC. `config_show_mobile_plan` is false. Camera laser overlay is false. `config_face_enroll` is empty.
- There is no CellBroadcast Bell MCC overlay (`values-mcc302-mnc610`). Talkman is not a Bell SKU.
- Framework overlay leftover (`b045cc4`): no `android.hardware.fingerprint` permission XML. No FPC HAL.
- `sepolicy/rild.te` leftover is unused. There is no rild package.
- Bluetooth overlay leftover: `profile_supported_sap` is true. There is no generated MAC.
- `init.talkman.rc` imports camera/nfc/gps. There is no duplicate `qcamerasvr` start. There is no CCI echo.
- Tethering hotspot provision arrays are empty (no LGE entitlement URL). `privapp-permissions-talkman.xml` dropped `com.lge.entitlement`.
- Mixer speaker path is QUAT_MI2S (TAS2553). Speaker-prot ACDB IDs are **14**. WCD SPK DRV is not wired.
- `init.talkman.bt.sh` leftover is QCA6174 persist `/persist/bdaddr.txt` or controller OTP. No generated MAC (`0d7a854`).
- `init.talkman.power.sh` leftover takes A57 offline then plugins cpu4/cpu5. Permanent offline is charger-only (`d2c43fb`).
- `extract-files.sh` dests match COPY_FILES. 32-bit `mot_imx230` and bu24210 `.kar` only. Banned dests: IMX377, OV5693, `libactuator_lc898212xd`, brcb032gwz, m24c64s, nanohub, OMADM, LGE entitlement, LifeTimer.
- `libgoog_eis_armeabi-v7a.so` and `libgoog_rownr.so` are **not** banned. They are
  `dlopen()` names in `libmmcamera2_imglib_modules.so` and `libmmcamera_imglib.so`,
  both of which ship, and `vendor.prop` sets `persist.camera.eis.enable=1`.
- `libmmcamera_imx230.so` is a second install of `libmmcamera_mot_imx230.so`, not a
  dump path. `setup-makefiles.sh` keeps it in a `derived` set, so
  `proprietary-files.txt` stays a pure dump manifest for `extract-files.sh`.
- WCNSS `wifi/WCNSS_qcom_cfg.ini` is QCA6174 2×2 (`gEnable2x2=1`, `gNumRxAnt=2`). No 11ax, no 6 GHz, no WPA3/SAE ini keys. MAC is not in this ini.
- Kernel `wlan.dtsi` is QCA6174 CNSS on PCIe0. The DT does not contain a MAC address.
- `init.talkman.usb.rc` is `g_android` sysfs. `sys.usb.configfs=0`. `BoardConfig` `androidboot.usbconfigfs=0`. No `/config/usb_gadget`. Default `persist.sys.usb.config=adb`.
- Thermal HAL package is `thermal.talkman` (`thermal/thermal.c`, vendor partition). `thermal-engine-8992.conf` copies to `/vendor/etc`. Not a P0 meter pass.
- Fluence UUIDs in `audio_effects.xml` are mic AEC/NS. They are not the TAS speaker path. `voice_processing` leftover is the same Fluence AEC/NS (`43b6f35`).
- `config.fs` assigns camera / nfc / gps AIDs (`a83a092`). Leftover bullhead caps stay.
- Overlay telephony `config_msim` is false (`f1b93a2`). Single SIM. No rild. Dual SIM is not this product.
- `dataservices` leftover is `librmnetctl` / `rmnetcli` for MSM8992 `rmnet_data`. It is not rild.
- `BoardConfig` leftover is QCA BT (no BCM). `BOARD_USB_CONFIGFS` is false. No FPC (`5f1d786`).
- GNSS leftover does not put a stock AOSP impl VINTF on the HIDL package (`903abd6`). `manifest.xml` lists GNSS and camera.provider. Health, power, and vibrator are `vintf_fragments` only. No radio. No FPC (`55b29f2`).
- Vibrator HIDL 1.0 `android.hardware.vibrator@1.0-service.talkman` writes qpnp-haptic `timed_output`. It is not the AOSP passthrough impl.
- QCOM `time_genoff` MATCH MSM8992 (`565f425`: ATS_DRM, ATS_TOD_MODEM).
- Kernel USB-C leftover is iCE5LP2K + HD3SS460 UFP mux. No PD (`2c5bf855dfd`).
- Kernel Duke WQHD leftover is dual-DSI command panel. TE is GPIO 10. Reset is GPIO 78 (`7fcefef793f`).
- TWRP overlay battery.capacity is 3000 (`cea7f03`). Kernel FG leftover cutoff/low is 3200/3500 (`91c0c0317c3`).
- VoLTE, VT, and WFC overlays are false. There is no rild package.
- CarrierConfig overlay sets IMS, VoLTE, WFC, and VT false. There is no Dual SIM.
- Telephony overlay IMS packages are empty (`config_ims_mmtel_package`, `config_ims_rcs_package`). Video-calling fallback is false. RTT is false. 5G DSDS is false (`49762ef`).
- Telephony leftover also sets `config_allow_hfa_outside_of_setup_wizard` false, `config_requestNetworkScan_disable` true, and an empty `config_simless_emergency_rtt_supported_countries` list. HFA is not SprintDM. Talkman is not a Sprint SKU. There is no Dual SIM.
- Telephony leftover also sets `config_enabled_lte` true, `config_support_simless_emergency_rtt` false, and empty `config_volte_provision_error_on_publish_response` / `config_rcs_provision_error_on_publish_response` arrays. There is no rild.
- Telephony leftover also sets `send_mic_mute_to_AudioManager` true and `hac_enabled` true. There is no rild.
- Telephony leftover Sprint MCC `values-mcc310-mnc120` still names SprintDM carrier settings. `support_swap_after_merge` is false. Talkman is not a Sprint SKU. There is no rild.
- ContactsCommon leftover (`f3b8ec1`) sets `config_allow_sim_import` false for Sprint MCC 310-120 / 311-490 / 311-870 / 312-530. That is not Dual SIM import.
- `media_codecs.xml` is Venus VFE44, 3840x2160 at 30 fps. There is no HEVC encode.
- `libshims` keeps `libcutils_shim`. Bullhead audio and empty sensor shims are gone.
- NFC overlay leftover (`1ccb479` MATCH `54afc57`): PN547, `enable_nfc_provisioning` false. No FeliCa SKU bools. `libnfc-nci.conf` is untouched. GPIOs stay in kernel `nfc.dtsi`.
- Bluetooth overlay is QCA6174. There is no generated MAC.
- `sepolicy/bluetooth.te` leftover is QCA6174 Rome. There is no generated MAC. SELinux stays permissive.
- Thermal HAL uses MSM8992 TSENS type names. Init chmod uses thermal_zone type and temp.
- Kernel ADC leftover names PA thermistors `pa_therm0` and `pa_therm1`.
- Vendor COPY_FILES for PIL use adsp, venus, and cpe. They do not use qcadsp8992.
- Kernel SD card detect is PM8994 GPIO 8. Haptic is PMI8994 ERM. HDMI 5 V enable is PM MPP4.
- There is no ORIGA2 Linux driver. Unknown pack charge uses OCV.
- `ueventd.talkman.rc` labels jpeg0 / jpeg3, video/media, flash_0/1 torch_0/1 flash_torch, pn547. No jpeg1/jpeg2. No `led::`.
- Camera sepolicy already covers vendor lib + XML. Init does not write CCI scan. SELinux stays permissive.
- Wi-Fi MAC comes from factory DPP. The image does not contain a MAC address.
- Sensors HAL is `sensors.talkman.so`. No BMI160. No nanohub. SAP names match ICM-206xx / AK09912 / ZPA2326.
- Speaker volume curves are AOSP defaults for TAS2553. Bullhead WCD DRC curves are gone. TAS PGA default is **11 dB**.
- TWRP kernel path is `kernel/mmo/msm8994`. TWRP config is `mmo_defconfig`.
- OTA assert is `talkman` only (no bullhead, no angler).
- Updater overlay leftover points at `Android4Lumia950/julian-ota` `talkman.json` and `changelog.txt`. Official `download.lineageos.org` bullhead/angler URLs are not used. Blocked-upgrade wiki is the personal device tree, not wiki.lineageos.org.
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
- Do not use Dual SIM RM-1118 / board 4VM_08d as talkman.
- Do not publish the Microsoft service schematic (PDF or page renders). Permission is use, not publish.

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
