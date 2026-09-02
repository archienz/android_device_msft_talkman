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

Unofficial zip `lineage-18.1-20260901-UNOFFICIAL-talkman` is installed on one RM-1104. The telephone boots to the home screen. Procedure: [`docs/INSTALL.md`](docs/INSTALL.md) and https://archienz.github.io/android_device_msft_talkman/INSTALL.html.

Host: Steam Deck SteamOS, ext4 `/home/deck/android/los-18.1`. Do not `repo sync` onto NTFS.

P0.1 Battery UI and P0.2 USB cable charge are **Working on this telephone**. P0.4 rear camera **live preview and stills** are on this telephone (kernel `#29`). Quick Settings flashlight is **Working on this telephone**. GPS is not. Dual SIM RM-1118 is not this product. There is no `CONFIG_MSM_OIS`. The Microsoft service schematic is for implementation only. It is not published.

| ID | Subsystem | Status | What is on the telephone | What is still missing |
|---|---|---|---|---|
| P0.0 | Rebuild LOS 18.1 | Built and flashed | `lineage_talkman-userdebug` zip 2026-09-01. Later **boot-only** flashes. Kernel `#29` 2026-09-02 17:33 AEST | Next bacon for vendor/system (carries flashlight HAL) |
| P0.1 | Battery UI | Working on this telephone | `dumpsys battery` live percent and voltage. Not 50 percent | — |
| P0.2 | Charge | Working on this telephone (USB cable) | USB `online`, SDP 5 V / 500 mA, `charging_enabled`, status Full. No PD | Qi pad not tested. `bms/charge_full` is still a bad health value |
| P0.3 | GPS | Not Working | GPSTest empty. `loc_eng_start`. 0 satellites. Modem OFFLINE | `numSvs` more than 0. MPSS online |
| P0.4 | Camera | Working on this telephone (rear preview and stills) | HAL **1** CameraId 0. Probe `mot_imx230`. CCI1 write **0x20** chip **0x0230**. CSI lane map **0x0423**. Mount-angle **90**. Snap live view and DCIM stills | Front camera not listed. AF / OIS not started. No photo strobe |
| — | Display / Wi-Fi / speaker / flashlight | Working on this telephone (QS torch) | 1440×2560. QCA6174. Loudspeaker. QS flashlight → HAL `set_torch_mode` → GPIO 12 `led:flash_torch` (`out/qa-torch-20260902/`). Owner confirmed 2026-09-02. Snap open turns the lamp off | Photo strobe (`flash_0`) not wired. Not P0 |
| P2 | RIL | Deferred | `ril-daemon` exit 1 | Modem SMD |

Keep QCamera2 MSMB `mot_imx230`. Do not ship CSID test-generator as camera. Rear CSI data lanes on RM-1104 are CSI0 LN2/LN1/LN3/LN0 (`qcom,csi-lane-assign = <0x0423>`), not Clark `0x4320`.

---

## Battery differences compared to the community repository

Community source: [Android4Lumia950/android_device_msft_talkman](https://github.com/Android4Lumia950/android_device_msft_talkman), branch `lineage-18.1-talkman`.

The status-bar percent is the **same path** on both trees: `qpnp-fg` (`bms`) to `qpnp-smbcharger` (`battery/capacity`) to Health autodectect. This tree does not hardcode 50 percent. A stock BV-T5E on the community ROM can show a live percent. A third-party pack can stick at 50 percent (fuel-gauge profile / battery ID, not the Health HAL).

| Item | Community | This tree |
|---|---|---|
| Percent, voltage, status | Generic `android.hardware.health@2.1-impl`. Autodetect `battery` | Same autodectect for those fields |
| Health HAL extra | No `health/` directory | `health/HealthImpl.cpp` (`android.hardware.health@2.1-impl-talkman`) pins `bms/charge_full`, `charge_full_design`, `cycle_count`, and energy from `charge_now` × `voltage_now` |
| Settings Battery Health | Off | On, those three `bms` nodes. On this telephone `charge_full` is still a bad value |
| `power_profile.xml` | Bullhead **2700** mAh | BV-T5E **3000** mAh (BatteryStats only) |
| Charge UI | Default “Charging” | “Charging (5V 1.8A)” / “Wireless charging (Qi 900mA)”. No PD. Fast threshold 15 W |
| Kernel (not this repo) | Battery-data phandle on **charger** only. FG cutoff 2800 mV, vbatt-low 4200 mV | Phandle also on **FG**. Cutoff 3200 mV, vbatt-low 3500 mV (WOA). CAF 3.10 `qpnp-fg.c` does not parse that phandle; it searches for a node named `qcom,battery-data` after the FG node. Charger parses the phandle on both trees |

Kernel fuel-gauge work is local on `kernel/mmo/msm8994`. It is not on the community kernel GitHub.

---

## Changes

The Changes list is [`changes.md`](changes.md).

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
| [archienz/android_kernel_mmo_msm8994](https://github.com/archienz/android_kernel_mmo_msm8994) | Personal kernel fork (`lineage-18.1-talkman`). Do not push `origin` (Android4Lumia950) |

Workspace notes on the build host: `C:\users\Archie\desktop\phone\docs\`.
