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

Do not mark P0 Working without `out/qa-*` logs from the telephone. Dual SIM RM-1118 is not this product. Do not invent a slave-id. The rear IMX230 write address on this telephone is **0x20** (chip **0x0230**), measured by CCI scan.

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
| Changes | [`changes.md`](changes.md) |
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
| Rear camera | Sony IMX230. CCI1 write **0x20**, SMIA `0x0016` chip **0x0230**. Module header `0xEACA`, manufacturer **0x0A**, rev major **5** → Windows DCC **10454105** (Karma). CSI `0x0423`. Mount-angle **90** |
| Front camera | Nokia/Microsoft **Ducati** SMIA module. CCI0 write **0x20**, `MODEL_ID` **0x2140**, manufacturer **0x0A**, `SENSOR_MODEL_ID` **0x03BB**, array 2600×1952 RAW10. Not IMX214 (`0x0214`). Die part not proven (`0x2016` = `0x0000`, HM5040 not confirmed). No CameraId 1. No `qcom,slave-id` |
| OIS / AF | Mitsumi **BU24210** on CCI1 write **0x7c** (sid `0x3e`, model `0x6500`). Firmware is DCC `.kar` (this module: `rev17_2` Karma). No `libmmcamera_ois_bu24210.so`. Do not bind `lc898212xd` |
| Speaker | TAS2553 on QUAT_MI2S. PGA **0x12** (11 dB). Chip default 15 dB brownouts an old BV-T5E |
| Bluetooth | QCA6174 Rome UART. Pairing works. Media A2DP does not (Android 11 `audio.bluetooth` HAL not packaged; leftover `a2dp_offload_cap` claims DSP offload this SoC does not have) |
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

Measured CCI addresses live in [`docs/CAMERA-IDENT.md`](docs/CAMERA-IDENT.md). They are not XML CameraId 1 and not a front `qcom,slave-id`.

Iris `qcom,camera@2` is **disabled** (CSI2 / CCI0 GPIO 14 / 102). No iris slave-id. No XML CameraId for iris.

Qi GPIOs match 4VM_08r: `wc-en` GPIO **2**, `wc-det` GPIO **14**.

---

## Progress (2026-09-05)

Source in Git is not a pass. A pass is a physical talkman log in `out/qa-*`.

Unofficial zip `lineage-18.1-20260901-UNOFFICIAL-talkman` is installed on one RM-1104. The telephone boots to the home screen. Procedure: [`docs/INSTALL.md`](docs/INSTALL.md) and https://archienz.github.io/android_device_msft_talkman/INSTALL.html.

Host: Steam Deck SteamOS, ext4 `/home/deck/android/los-18.1`. Do not `repo sync` onto NTFS. Do not Ubuntu Distrobox.

P0.1 Battery UI and P0.2 USB cable charge are **Working on this telephone**. P0.4 rear camera **live preview and stills** are on this telephone (kernel `#29`). Quick Settings flashlight is **Working on this telephone**. GPS is not. Front camera is measured and is **not** in the HAL. AF / OIS firmware load is **not** a lens move. Dual SIM RM-1118 is not this product. There is no `CONFIG_MSM_OIS`. The Microsoft service schematic is for implementation only. It is not published.

| ID | Subsystem | Status | What is on the telephone | What is still missing |
|---|---|---|---|---|
| P0.0 | Rebuild LOS 18.1 | Built and flashed | `lineage_talkman-userdebug` zip 2026-09-01. Later **boot-only** flashes. Kernel `#29` 2026-09-02 17:33 AEST (camera preview). Later AF lab images are local only | Next bacon for vendor/system (flashlight HAL, photo strobe, RIL shim, Bluetooth audio HAL) |
| P0.1 | Battery UI | Working on this telephone | `dumpsys battery` live percent and voltage. Not 50 percent | — |
| P0.2 | Charge | Working on this telephone (USB cable) | USB `online`, SDP 5 V / 500 mA, `charging_enabled`, status Full. No PD | Qi pad not tested. `bms/charge_full` is still a bad health value |
| P0.3 | GPS | Not Working | GPSTest empty. `loc_eng_start`. 0 satellites. Modem OFFLINE | `numSvs` more than 0. MPSS online. `rild` must load first |
| P0.4 | Camera | Working on this telephone (rear preview and stills) | HAL **1** CameraId 0. Probe `mot_imx230`. CCI1 write **0x20** chip **0x0230**. CSI lane map **0x0423**. Mount-angle **90**. Snap live view and DCIM stills. QS torch on GPIO 12 | Front not listed (Ducati `0x2140` / die `0x03BB` measured; no XML). AF fixed until BU24210 moves. Photo strobe is in Git, not in the 2026-09-01 zip |
| — | Display / Wi-Fi / speaker / flashlight | Working on this telephone (QS torch) | 1440×2560 at 60 Hz. QCA6174. Loudspeaker at TAS PGA **11 dB**. QS flashlight → `set_torch_mode` → `led:flash_torch` (`out/qa-torch-20260902/`). Touch input boost: A57 1248 MHz + GPU 300 MHz for 1.5 s | Speaker is quieter than Windows on purpose (brownout). Bluetooth media stays on the speaker |
| — | Bluetooth audio | Not Working (media) | Pair / LE connect on QCA6174 | A2DP: package `audio.bluetooth.default` + `android.hardware.bluetooth.audio@2.0-impl`. Drop fake `a2dp_offload_cap` |
| P2 | RIL | Deferred | `ril-daemon` exit 1 every 5 s: `libril-qc-qmi-1.so` missing `AudioSystem::setErrorCallback` | `libaudioclient_shim` in system image. Then MPSS vote |

Keep QCamera2 MSMB `mot_imx230`. Do not ship CSID test-generator as camera. Rear CSI data lanes on RM-1104 are CSI0 LN2/LN1/LN3/LN0 (`qcom,csi-lane-assign = <0x0423>`), not Clark `0x4320`. Do not bind `libactuator_lc898212xd`. Do not add CameraId 1 until a front HAL exists for die `0x03BB`.

---

## Differences compared to the community repository

Community source: [Android4Lumia950/android_device_msft_talkman](https://github.com/Android4Lumia950/android_device_msft_talkman), branch `lineage-18.1-talkman`.

This tree is a personal fork for RM-1104 / board **4VM_08r**. The community tree is the start point. Dual SIM RM-1118 is not this product.

A function is **Working on this telephone** only with `out/qa-*` logs. The community column is the public tree. It is not a log from this RM-1104.

| Function | Community tree | This tree on this telephone |
|---|---|---|
| Rear camera | Clark CSI map **0x4320**. Bullhead sensor libraries (`imx377`, `ov5693`) in the probe list. No `mot_imx230` match. Snap has no live view | Clark `mot_imx230`. CSI map **0x0423**. Mount-angle **90**. Snap live view and DCIM stills. **Working on this telephone** |
| Front camera | No CameraId 1. Module name not measured in that tree | CCI0 write **0x20**, Ducati module **0x2140**, die **0x03BB**. No CameraId 1. No `qcom,slave-id` |
| AF / OIS | No BU24210 driver. Bullhead `lc898212xd` is a wrong bind | CCI1 write **0x7c** is BU24210. No `lc898212xd`. Lens does not move |
| Flashlight | HAL has no flash unit. The Quick Settings tile shows Camera in use | `set_torch_mode` writes `led:flash_torch` (GPIO 12). **Working on this telephone** |
| Speaker | TAS2553 on QUAT_MI2S in later community files. Some mixer files still name WCD speaker-prot | TAS2553 on QUAT_MI2S. PGA **11 dB**. Playback works. The gain is lower than Windows (brownout at 15 dB) |
| Bluetooth media | QCA6174 pair | Pair works. Media stays on the speaker. The Android 11 `audio.bluetooth` HAL is not in the package list |
| Battery percent | `qpnp-fg` → `qpnp-smbcharger` → Health autodectect. No hardcoded 50 percent | Same path. No hardcoded 50 percent. **Working on this telephone** |
| Battery Health | Generic `android.hardware.health@2.1-impl`. No `health/` | `HealthImpl.cpp` pins `bms/charge_full`, `charge_full_design`, `cycle_count`. `charge_full` is still a bad value |
| Charge (USB) | Cable charge through smbcharger | USB SDP 5 V / 500 mA. **Working on this telephone**. Qi pad not tested. UI strings are 5 V 1.8 A and Qi 900 mA. No PD |
| `power_profile.xml` | Bullhead **2700** mAh | BV-T5E **3000** mAh (BatteryStats only) |
| Fuel-gauge kernel | Phandle on the **charger** node. Cutoff 2800 mV. vbatt-low 4200 mV | Phandle also on **FG**. Cutoff 3200 mV. vbatt-low 3500 mV (WOA). This change is in `kernel/mmo/msm8994`. It is not on the community kernel GitHub |
| GPS | `loc_eng_start`. 0 satellites when MPSS is OFFLINE | Same. Modem stays OFFLINE until `rild` loads |
| RIL | `ril-daemon` does not stay up | Measured miss: `AudioSystem::setErrorCallback` in `libril-qc-qmi-1.so`. Shim is not in the installed zip |
| Display / touch | 1440×2560 at 60 Hz | Same panel. GPU floor **300 MHz** and A57 **1248 MHz** for 1.5 s after touch |
| USB | CAF `g_android` | `g_android`. No USB_CONFIGFS. No PD |
| LifeTimer | Bullhead APK. PackageManager crash loop | Not in the package list |
| CSID test-generator | Not a camera | Do not ship |

The status-bar percent uses the **same** fuel-gauge path on both trees. A stock BV-T5E shows a live percent. A third-party pack shows 50 percent when the fuel-gauge profile does not match. That is not the Health HAL.

CAF 3.10 `qpnp-fg.c` does not parse the battery-data phandle. It searches for a node named `qcom,battery-data` after the FG node. The charger parses the phandle on both trees.

---

## Changes

The Changes list is [`changes.md`](changes.md).

---

## What you must not do

- Do not invent a CCI slave ID.
- Do not add CameraId 1 or a front `qcom,slave-id` until a HAL exists for die `0x03BB`.
- Do not bind `libactuator_lc898212xd` or name the front die HM5040 in DT.
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

Build on SteamOS ext4 (`/home/deck/android/los-18.1`). Do not Ubuntu Distrobox. Do not `repo sync` onto NTFS.

1. Clone LineageOS 18.1 with the talkman local manifest.
2. Put this tree at `device/msft/talkman`.
3. Put the kernel at `kernel/mmo/msm8994` (branch `lineage-18.1-talkman`).
4. Put vendor at `vendor/msft/talkman` (branch `lineage-18.1-julian`).
5. Run `source build/envsetup.sh`.
6. Run `lunch lineage_talkman-userdebug`.
7. Run `mka bacon`.

Flash **boot only** on a black LK2ND screen (`18D1:D00D`). Do not EDL. Do not wipe userdata. Strings in `boot.img` must include `mot_imx230` and `talkman-cci-scan`.

Do a check of `docs/QA-CHECKLIST.md` after the first boot.

---

## Related personal repositories

| Repository | Role |
|---|---|
| [archienz/android_device_msft_talkman](https://github.com/archienz/android_device_msft_talkman) | This device tree |
| [archienz/android_vendor_msft_talkman](https://github.com/archienz/android_vendor_msft_talkman) | Vendor copy files |
| [archienz/android_kernel_mmo_msm8994](https://github.com/archienz/android_kernel_mmo_msm8994) | Personal kernel fork (`lineage-18.1-talkman`). Do not push `origin` (Android4Lumia950) |

Workspace notes on the build host: `/home/deck/Desktop/phone/docs/` (local). The Microsoft service schematic stays there. It is not in this repository.
