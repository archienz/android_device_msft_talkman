# Changes

This file is a description of the tree. It is not a procedure.

Purpose, Progress, and differences compared to the community repository stay in [`README.md`](README.md).

### Front camera ident (2026-09-02, measured, not in HAL)

- Logs: `out/qa-cam-20260902/` (`FRONT-SENSOR-ID.md`, `front-smia-regs.txt`, `front-hm5040-check.txt`). Scanner holds L17 + MCLK2 and releases `CAM_FRONT_RES_N` GPIO **104**.
- CCI **master 0**, 7-bit `0x10`, write **0x20**. Scan: `model=0x2140 chip=0x03bb`.
- SMIA module: `MODEL_ID` **0x2140**, `MANUFACTURER_ID` **0x0A**, SMIA 1.0. That is Nokia/Microsoft **Ducati** (DCC `0A214000` / `0A214001`). It is **not** Sony IMX214 (`SENSOR_MODEL_ID` would be `0x0214`).
- Die: `SENSOR_MODEL_ID` **0x03BB**, sensor manufacturer `0x0019` = `0x01`, native array **2600×1952** RAW10 CSI-2. Public Linux CCS tables have no `0x03BB`. MediaTek `HM5040_SENSOR_ID` is `0x03BB` at Himax `0x2016`; on this telephone `0x2016` reads **0x0000**. HM5040 is **not** confirmed. Do not name a part in DT or XML.
- No CameraId 1. No front `qcom,slave-id`. Do not bind `libmmcamera_ov5693` or IMX214 as front.

### Rear AF / OIS (2026-09-03, lab)

- Companion on CCI1 write **0x7c** is Mitsumi **BU24210**. Rear module NVM / SMIA header: model `0xEACA`, manufacturer `0x0A`, rev major **5** → DCC **10454105** → firmware `bu24210_dl_ds1_8x1_rev17_2_Trial_Mitsumi_ST-Karma.kar`.
- Windows ARM32 `qccamrearsensor_primarySMIApp8992.sys` protocol (static): DTI pages through `0x0581` / `0x0583` / `0x0584` (64-byte max), then OIS_INIT at `0x0550`. AF position is a later write after firmware. Report: `out/qa-ois-re/BU24210-PROTOCOL.md`.
- On the telephone: DTI page writes ACK. `0x0524` stays `0x01`. First `0x0550` write NAKs and the chip leaves the bus. Same on rev11 / bu24214 / Mersu rev52. SMIA AF descriptor `0x1B04` / `0x1B40` is empty cold (`focus-mode: fixed` until a real 0x7c driver exists).
- Do not bind `libactuator_lc898212xd`. No `libmmcamera_ois_bu24210.so`. No `CONFIG_MSM_OIS`. Kernel `talkman-cci-scan` `ois` / `i2c` / `power` commands are the lab path.

### Photo strobe (Git `d3597bc`, not in the 2026-09-01 zip)

- HAL1 still capture can light `led:flash_torch` (GPIO 12) around `take_picture`, wait for AEC, then off. Modes `off,auto,on,torch`. `led:torch_0` is never written. Live snapshot during video does not strobe. EXIF Flash still says not fired.
- Quick Settings torch path is unchanged (`1fc5b8a`).

### GPU / touch (2026-09-02, measured `out/qa-gpu-touch-20260902-1749/`)

- Panel is 60 Hz TE (16.67 ms). Touch report ~113 Hz. Do not invent 90/120 Hz.
- `powerhint.xml` + `init.talkman.power.sh`: GPU wake/floor **300 MHz**, A57 input boost **1248 MHz** for 1.5 s, `sched_boost_on_input`. SurfaceFlinger `debug.sf.*.sf.duration=5.5 ms`, app **15.5 ms**.
- Synaptics S3708 F01 report-rate bit is ignored by firmware.

### Bluetooth media (2026-09-05, tree read, no ADB)

- Pairing uses QCA6174 Rome. Media stays on the TAS.
- Tree ships `audio.a2dp.default` and `a2dp_audio_policy_configuration.xml`. Android 11 needs `audio.bluetooth.default` and `android.hardware.bluetooth.audio@2.0-impl` plus `bluetooth_audio_policy_configuration.xml`.
- `persist.vendor.bt.a2dp_offload_cap=sbc-aptx-aptxtws-aptxhd-aac-ldac` claims DSP offload. MSM8992 HAL has no `AUDIO_FEATURE_ENABLED_A2DP_OFFLOAD`. Not measured on the telephone this day.

### RIL (2026-09-02, measured, shim not in the zip)

- `ril-daemon` restarts: `dlopen failed: cannot locate symbol AudioSystem::setErrorCallback` from `libril-qc-qmi-1.so`. MPSS stays OFFLINE because rild never votes `subsystem_get("modem")`. GPS 0 satellites follows.
- Bullhead-style `libaudioclient_shim` maps `setErrorCallback` → `addErrorCallback`. Needs a **system** image (linker64 `TARGET_LD_SHIM_LIBS`). Boot-only cannot prove it.

### Kernel boot-only items (2026-09-02, kernel `2b59cf6d3f6`, not yet on the telephone)

These live in `android_kernel_mmo_msm8994` and need only a `boot.img` flash. None is measured yet.

- Modem: stock `msm8992.dtsi` marks the APPS↔MODEM SMD edge `qcom,not-loadable`. Then `smd_edge_to_pil_str()` is NULL and nothing in the kernel calls `subsystem_get("modem")`; only the QMI peripheral-manager vote from `rild` boots MSS. `common/talkman-modem.dtsi` deletes that flag, so the first `smd_pkt` open (qmuxd on `DATA5_CNTL`, retried every second) runs `pil_boot("modem")`. `firmware_class.c` `fw_path` has `/firmware/image` (the GPT modem partition from `fstab.talkman`), where `mba.b00`, `mba.mbn`, `modem.mdt` are. The IPC-router XPRT keeps `qcom,disable-pil-loading`: it probes before `/firmware` is mounted and does not retry. Success is `pil-q6v5-mss` / `subsys-restart: modem ONLINE` in `dmesg` and GPS `numSvs` > 0. A TZ reject shows as `pil-q6v5-mss ... error` on the same boot.
- Qi: PM8994 GPIO **2** (`WLC_EN`) and GPIO **14** (`WLC_DET`) are digital inputs, no pull. The receiver `EN` polarity is not on the drawing and the telephone Qi-charges with the AP off, so `WLC_EN` stays at the receiver default. Read `/sys/kernel/debug/qpnp_pin/pm8994-gpio/2` and `14` and `power_supply/dc/present` on a pad before any output is driven.
- USB-C `common/usbc.dtsi` (PMI8994 GPIO 5 VBUS switch, GPIO 8/9/10 HD3SS460) is committed; `msm8992-chi.dtsi` at HEAD already included it. No PD.
- Camera pinctrl `cam_sensor_front_rst_*` (GPIO 104) and `cam_sensor_iris_*` (GPIO 102), LVS1 always-on, L25 init 1.15 V, torch label `led:flash_torch`, TAS2552 PGA 11 dB are committed (were working-tree only).
- `talkman-cci-scan`: the front sweep now releases `CAM_FRONT_RES_N` (GPIO 104) after L17 + MCLK2. A sensor in reset never ACKs; that is why the front half of every scan was empty. New debugfs `power` (`rear` / `front` / `off`, holds rails + MCLK + CCI INIT) and `i2c` (`r|w <master> <sid7> <reg> [val] [alen] [dlen]`). This is the tool for the BU24210 at write `0x7c` (sid `0x3e`, L23 VAF on): the `.kar` header byte 4 is `0x7c`, and Rohm publishes no BU24210 register map, so a lens move needs a register found on the telephone, not a guessed one. No `qcom,actuator` node: CAF `msm_actuator` takes the slave address from the userspace actuator library, so a node without `ActuatorName` does nothing. No `lc898212xd`, no `CONFIG_MSM_OIS`.
- `cpu-boost`: on `mmo,talkman` the kernel defaults are `input_boost_ms` 1500, `input_boost_freq` 0-3:960000 4-5:1248000, `sched_boost_on_input`. Same values as `init.talkman.power.sh` / `powerhint.xml`. KGSL `qcom,initial-pwrlevel` was already 4 (300 MHz).
- Touch: the `synaptics,rmi4` driver never writes F01 `report_rate`; the panel firmware default stands. No kernel register raises it. Measure with `getevent -t` before changing anything.

### Quick Settings flashlight (2026-09-02)

- Measured on the telephone (`out/qa-torch-20260902/`): the tile said **Camera in use** with no camera client. `dumpsys media.camera` said `Has a flash unit: false`. SystemUI `FlashlightControllerImpl` had `mCameraId=null`, `mTorchAvailable=false`. The tile shows that string whenever `mTorchAvailable` is false; it never reached `setTorchMode`. There was no `CAMERA_IN_USE` and no held device.
- Cause: mm-camera has no flash driver for this board (no `FlashName`, no sky81296, `flash subdev id = -1`, `led flash is not supported for this sensor`). HAL1 then set no `flash-mode-values`, so cameraserver `DeviceInfo1` saw no torch and `FLASH_INFO_AVAILABLE` was false. The module was API 2.3 with `set_torch_mode = NULL`.
- Fix in `camera/QCamera2`: `util/QCameraTorch.cpp` writes **only** `/sys/class/leds/led:flash_torch/brightness` (0 or `max_brightness`). The module is API **2.4** with `QCamera2Factory::set_torch_mode`. It returns `-EBUSY` while a device is open and sends `torch_mode_status_change`. `open()` turns the LED off and sends `NOT_AVAILABLE`; `close()` sends `AVAILABLE_OFF`. `getCameraInfo` sets `resource_cost` 100 (API 2.4 makes it HAL-owned).
- HAL1 parameters: when the backend has 0 flash modes and the LED node exists, `flash-mode-values` is `off,torch` and `updateFlash` drives the LED. `CAM_INTF_PARM_LED_MODE` is never sent to the daemon in that mode, so preview and ZSL are unchanged.
- Result: tile ON → `led:flash_torch` 255, `torch_0` 0, `Device 0 is closed`. Tile OFF → 0. Snap open → LED 0 and tile **Camera in use** (correct). Snap close → tile available. Snap preview frames present at 30 fps before and after (SurfaceFlinger latency). `screencap` shows the MDP YUV overlay as black with the old HAL too; it is not a regression.
- `liblight/lights.c` `LIGHT_ID_FLASHLIGHT` also writes only `led:flash_torch`. `led:torch_0` is the red indicator.
- Owner confirmed 2026-09-02: Quick Settings flashlight works. Keep `1fc5b8a`.
- `cmd statusbar click-tile` / `remove-tile` crash SystemUI (`CustomTile.toSpec` NPE, a custom tile with a null component in the tile list). Not fixed here. Use `input tap`.

### Install and first boot (2026-09-02)

- Procedure: [`docs/INSTALL.md`](docs/INSTALL.md). Pages: https://archienz.github.io/android_device_msft_talkman/INSTALL.html. How to update Pages is in that file.
- `manifest.xml` does not list health 2.1, power 1.0, or vibrator 1.0. Those HALs ship `vintf_fragments`. A duplicate list made `hwservicemanager` reject the device manifest (`HAL vibrator has a conflict`). SurfaceFlinger then aborted `gralloc-mapper is missing` (black screen).
- Do not package `LifeTimerService`. The APK is a bullhead leftover. PackageManager whitelist crash loops `system_server`.
- Snap `CameraLauncher` is disabled when the HAL has 0 cameras. That hid the icon on first boot. The HAL now reports **1** camera. First Snap open can still hit `PhotoModule.initializeFocusManager` index 0 on an empty list. Second open: `startPreview failed` (`isp_util_map_streams` sensor resolution **0x0**, iface→ISP link). No JPEG.
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

Compared to the community repository: [`README.md` Differences](README.md#differences-compared-to-the-community-repository).

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

### Camera (2026-09-02, rear live preview)

- Kernel `#28` on this telephone (boot-only flash). `mot_imx230` probe succeeds.
  Snap shows a moving preview. Stills land in DCIM.
- CSI lane map is board-specific: `qcom,csi-lane-assign = <0x0423>` (IMX230
  DL0..DL3 to CSI0 LN2/LN1/LN3/LN0). Clark blob `0x4320` made CSID count
  packets with ECC errors and no VFE frame. XML `LaneAssign` matches 0x0423.
- 20nm CSIPHY MISC1 is stock CAF (`00/04/28/18/08`).
- HAL1 dumpsys `Orientation: 0` because XML/DT `MountAngle` was **360**.
  Rear module is **90**. XML and DT updated. Open Snap after cameraserver restart.
- Front SMIA is still not a CameraId. AF / OIS not started. No FlashName.

### Camera (2026-09-02, after first boot)

- CCI scan on the telephone: rear CSI0 / CCI **master 1** ACK write **0x20**,
  id **0x0230**. That is IMX230. Master 0 sid **0x30** chip **0x0250** is not the
  pixel array. Kernel DT `qcom,slave-id = <0x20 0x0016 0x0230>` is that
  measurement. It is not an invented id.
- Clark `libmmcamera2_sensor_modules.so` is on `/vendor` (list includes
  `mot_imx230`). Linker also needs `libflash_sky81296.so` and
  `libmotocalibration.so` at load. XML still has no FlashName / OisName /
  ActuatorName / EepromName. Torch is GPIO 12.
- Kernel `#21`: HAL **1** camera. `openCamera` rc 0. Snap preview still fails
  (ISP `sensor resolution: 0x0`). CSID ioctls seen: INIT and RELEASE. No
  `CSID_CFG` before the ISP error. No JPEG.

### Camera

- XML `SensorName` is `mot_imx230` for CameraId 0.
- Snap overlay is CameraId 0 `mot_imx230` HAL1. `support_camera_api_v2` is false. There is no Dual SIM CameraId 1.
- There is no CameraId 1. Front sensor name is not known. Iris `qcom,camera@2` is disabled. No iris XML.
- CAMERA-IDENT: CCI master 1 is a bus index. Rear `qcom,slave-id` is the **measured** CCI1 ACK: write **0x20**, id register **0x0016**, chip **0x0230**. Clark blob still sends revision I2C to **0x34**; the kernel uses **0x20**.
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
- Light HIDL 2.0 writes lcd-backlight and RGB sysfs. Torch writes only `led:flash_torch` (`d92e6c3` also wrote `led:torch_0`; that is the red indicator). Torch GPIO is **12**. HIDL 2.0 has no `Type::FLASHLIGHT` enum; torch stays on the liblight `LIGHT_ID_FLASHLIGHT` path and the `QCameraTorch` GPIO LED backend in the camera HAL. Kernel `flash.dtsi` is PMI8994 qpnp-flash-led with that GPIO. sepolicy `hal_light` sysfs_leds matches those names (`6a8f621`). There is no leftover `led::flash_torch`.
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
