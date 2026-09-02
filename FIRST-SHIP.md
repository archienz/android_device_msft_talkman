# First-ship record — talkman tip 76bdeca

This file is the first-ship data for the personal **archienz** talkman device tree.

The device is Microsoft Lumia 950 (`talkman`, RM-1104 / RM-1105 / RM-1108). The SoC is **MSM8992**.

This file is **not** a copy of `README.md`. `README.md` is the tree description. This file records the locked facts for tip `76bdeca`. Older tips stay as history below.

Vocabulary in this file follows **ASD-STE100** Simplified Technical English (Issue 9) style.
Vocabulary was checked against known rulings and high-risk patterns only, not against the official ASD-STE100 Part 2 dictionary.
Full compliance needs a check against the official standard.

---

## Purpose

This repository is the personal **archienz** LineageOS 18.1 device tree for talkman.

The write branch is `lineage-18.1-talkman-hw`. Write path is the **archienz** fork only.

This document is for talkman only. Dual SIM is out of scope.

Do not push `lineage-18.1-talkman-hw` from a `cursor/*` side branch.

---

## Tip / HEAD for this document

| Item | Value |
|---|---|
| Short SHA | `76bdeca` |
| Full SHA | `76bdeca2bf2d79ab6e6740f2e58761f863631672` |
| Subject | sf: app duration 15.5 ms, SF stays 5.5 ms |
| Author | archienz |
| Parent | `2c89f611a2ebe376c3784799e6626c6497e415b4` |
| Files in this commit | `system.prop` only |
| Branch | `lineage-18.1-talkman-hw` |
| Repository | [archienz/android_device_msft_talkman](https://github.com/archienz/android_device_msft_talkman) |
| Lunch target | `lineage_talkman-userdebug` |
| Product | RM-1104 only |

The protected tip moved: `2c89f61` → `76bdeca`. The owner **archienz** wrote that commit. This document records tip `76bdeca`.

This tip is SurfaceFlinger timing. It is **not** a camera land.

This document does **not** change `README.md`, `system.prop`, powerhint, mixer, `lights.c`, rild, camera XML, or any C++. Those files stay as the owner wrote them.

| Step | Full SHA | Subject |
|---|---|---|
| Older | `31a5359909e07703770492861d00415a0b619733` | health HAL, vendor GPS loc, GPIO torch, CAF compile patches |
| Older | `cd18318881bbb3a6c6b2d779a5554efce474c76c` | drop illegal device-added-/dev/pn547 init trigger |
| Older | `96713de5511033555cb4d3407c242210daee1e21` | stop shipping recovery overlay /etc |
| Older | `1387c661bd57bb4621bdb62b0777d58144030251` | install recovery.fstab under system/etc |
| Older | `6da0d97a9c3640faf9e0f2b377987603e527188b` | label /bt_firmware for e2fsdroid |
| Older | `025df9cc0c01c081249fb5cc7cb0878f747ca172` | Progress — unofficial talkman zip exists on the Steam Deck |
| Older | `3925712e8d6ebe0c2500195cc3e02e1c14dadedb` | install procedure and first-boot findings; VINTF de-dupe |
| Older | `39c8eb23a8f45c9bec6278c17d57b1783da6185d` | Jekyll config for GitHub Pages /docs |
| Older | `c6844a7744c147e7b06a41c996457f848421dfc6` | expand install procedure, findings, and Pages update |
| Older | `8ce324b8c0c1ecc7fd5580944b10a5b66f207bb1` | record why the camera probed imx377, and fix the blob ban list |
| Older | `b0fe90d2ad78b599c9f9227a112229de46c022cf` | camera HAL lists CameraId 0; Snap preview still fails |
| Older | `dcdd7a4394451d6d4f85405bece7d5027ddc6583` | Battery UI and USB cable charge work on this telephone |
| Older | `f65cdccf63fb23d510090ff6ee4d7daabd002042` | move Changes to changes.md; note battery vs community |
| Older | `f8b2e890923cb5e9a801fefbf5c73ae2a98d0714` | refuse fuel-gauge capacity and cycle values that cannot be real |
| Older | `1e64790fbaea934255751ad3f669eb7c5e89b0be` | Clark QCamera2 HAL + preview teardown deadlock fix |
| Older | `a84476830d3e3f1767128b2bc7cb3d284cba354f` | keep cameraserver alive across boot_completed; HAL to thermal-engine |
| Older | `f63634f173410435961d58f7afe17a4ffaf126b7` | rear IMX230 live preview docs; MountAngle 90 |
| Older | `42074ababefd395e0dcbcff75d24da7d12acc2c9` | Cursor workspace bind (AGENTS.md + talkman.mdc) |
| Older | `7557043ef7d1fba11e4de686cc4b42b91a780f6d` | GPU 300 MHz floor; earlier SF app phase |
| Older | `2ce6daad77db77eae100d5207d8a8386220799ab` | one-vsync SF phase (5.5 ms SF, 11 ms app) |
| Older | `2c89f611a2ebe376c3784799e6626c6497e415b4` | 1.5 s A57 input boost with HMP sched boost |
| Documented tip | `76bdeca2bf2d79ab6e6740f2e58761f863631672` | app duration 15.5 ms; SF stays 5.5 ms |

---

## App duration 15.5 ms (this tip)

This tip is `system.prop` only. No C. No sepolicy. No chmod.

Measured on the telephone with SF 5.5 / app 11.0 live (Settings fling and drag, `gfxinfo` framestats + SurfaceFlinger `--latency` retire fences):

| Item | Fact |
|---|---|
| vsync→queueBuffer p50 | 8.6–9.2 ms |
| vsync→queueBuffer p90 | 10.7–14.2 ms |
| Late TE at app 11.0 | 7–15 percent of frames missed the 11.17 ms SF latch and presented one TE (16.7 ms) late. `gfxinfo` jank% does not see this. |
| App 15.5 ms | App wakes 4.3 ms before the vsync. |
| Late-TE rate in flings | Drops to 0.9 percent (3/335, two runs). |
| touch→TE p50 | 32–34 → 37 ms in continuous scrolling (+4.3 ms). Still one TE better than 27.6. |
| Sum | One TE for SF. No 27.6. |

`debug.sf.*.app.duration` 11.0 → 15.5 ms. SF stays 5.5 ms.

This is **not** a camera land.

Keep the GPU 300 MHz floor as **observed** from tip `7557043`. Keep the A57 1.5 s input boost as **observed** from tip `2c89f61`. Keep one-vsync SF history from tip `2ce6daa`. Keep `MountAngle` 90 / `LaneAssign` 0x0423 / Kernel #28 preview+stills as **observed** from tip `f63634f`.

Do **not** mark P0.4 **Working**. Camera stays **Not Working** until `out/qa-*` logs, even if stills are claimed.

Do **not** mark P0.1 or P0.2 **Working**. Working needs `out/qa-*` logs. Keep the observed dumpsys / USB Full claims from tip `dcdd7a4`. GPS (P0.3) stays **Not Working**. Dual SIM remains out of scope.

---

## Pass rule

Source in Git is **not** a pass.

A pass needs `out/qa-*` logs from the telephone.

Do not mark any P0 item **Working** without those logs.

| ID | Subsystem | Status at tip `76bdeca` | Observed on this telephone | What is still missing for a pass |
|---|---|---|---|---|
| P0.1 | Battery UI | Not Working | Live `dumpsys` percent and voltage. Not a hardcoded 50 percent. (Tip `dcdd7a4` claim.) | `out/qa-*` logs |
| P0.2 | Charge | Not Working | USB cable online. SDP 5 V / 500 mA. Status Full. Qi pad not tested. No inline USB meter. (Tip `dcdd7a4` claim.) | `out/qa-*` logs. Qi pad. |
| P0.3 | GPS | Not Working | 0 satellites. MPSS offline. | GPSTest `numSvs` more than 0. |
| P0.4 | Camera | Not Working | Kernel #28 Snap live preview and stills (claimed). `MountAngle` 90. `LaneAssign` 0x0423. HAL lists CameraId 0. CCI1 ACK write 0x20 / chip 0x0230. | `out/qa-*` logs |

---

## Draft pull request 6 (GNSS clamp + thermal socket)

This section records rebase status only. The pull request is **not** merged. It is **not** a GPS pass.

| Item | Fact |
|---|---|
| Pull request | [Draft pull request 6](https://github.com/archienz/android_device_msft_talkman/pull/6) |
| Title | talkman: clamp GNSS debug string and nav message length |
| Head | `f017afa51183fd12ed09f0702e12ccda7450c4da` (was `26efeb4`) |
| Head branch | `cursor/cve-pass9-hw` |
| Base | `lineage-18.1-talkman-hw` at `76bdeca2bf2d79ab6e6740f2e58761f863631672` |
| Size | 2 commits, 3 files |
| Files | `gnss/1.0/default/GnssDebug.cpp`, `gnss/1.0/default/GnssNavigationMessage.cpp`, `rootdir/etc/init.talkman.rc` |
| `GnssDebug.cpp` | Uses `std::min` (not `std::max`). Clamps retained. |
| `GnssNavigationMessage.cpp` | Clamps with `sizeof(message->data)`, not 40. Clamps retained. |
| `init.talkman.rc` | Pass 23 FIX kept: `thermal-recv-client` is `0660 system camera` (CAF recv-client mode). Tip `a844768` had `0666` (world-writable). |
| Pass 11 | SKIP on `53e7195..31a5359`. GNSS files were not in that range. |
| Pass 12 | SKIP on `31a5359..cd18318`. NFC init trigger drop only. GNSS files were not in that range. |
| Pass 13 | SKIP on `cd18318..1387c66`. Recovery fstab path only. No GNSS. |
| Pass 14 | SKIP landed on `1387c66..6da0d97`. `e2fsdroid` `/bt_firmware` label only. No GNSS. |
| Pass 15 | SKIP landed on `6da0d97..025df9c`. README Progress zip only. No GNSS. |
| Pass 16 | SKIP landed on `025df9c..c6844a7`. Install docs, Pages, and `manifest.xml` VINTF de-dupe only. No GNSS. |
| Pass 17 | SKIP landed on `c6844a7..8ce324b`. Host-side extract/docs only. No C/HAL/init/DAC. |
| Pass 18 | SKIP landed on `8ce324b..b0fe90d`. Docs only. No C/HAL/init/DAC. |
| Pass 19 | SKIP landed on `b0fe90d..dcdd7a4`. Docs only. No C/HAL/init/DAC. |
| Pass 20 | SKIP landed on `dcdd7a4..f65cdcc`. Docs only (`README.md`, `changes.md`, `docs/index.md`). No C/HAL/init/DAC. |
| Pass 21 | SKIP landed on `f65cdcc..f8b2e89`. Health gate + Settings overlay comments. Verified not rubber-stamped: `UpdateHealthInfo` `int32` gates + `LOG` streams, no `sprintf`/`strcpy`; `WithinTolerance` `int64_t`; `ReadInt64` `ReadFileToString`+`ParseInt`; overlay comments only, no DAC. |
| Pass 22 | SKIP landed on `f8b2e89..1e64790`. Clark QCamera2 C++ inspected: `putBufs` `cond_signal` then `pthread_join`; `CAM_INTF_PARM_MAX` 213 ABI match not OOB; dump `open` 0777 theater SKIP; no new `strcpy`/`sprintf`/`setToExternal`. |
| Pass 23 | **FIX** (not SKIP) on tip `a844768`. `thermal-recv-client` `0660 system camera` (CAF recv-client mode). Tip had `0666` world-writable. GNSS clamps retained. |
| Pass 24 | SKIP landed on `a844768..f63634f`. Docs/XML only (`README.md`, `changes.md`, `camera/msm8992_camera.xml`, `configs/msm8992_camera.xml`). `MountAngle` 360→90 and `LaneAssign` 0x4320→0x0423 are CSI / orientation config, not a CVE. No 0666/0777. No C/init/DAC. |
| Pass 25 | SKIP landed on `f63634f..42074ab`. Cursor meta only (`AGENTS.md`, `.cursor/rules/talkman.mdc`). No HAL/C++/sepolicy/init/XML. No DAC. |
| Pass 26 | SKIP landed on `42074ab..7557043`. GPU/SF timing only (`powerhint.xml`, `init.talkman.power.sh`, `system.prop`). No chmod/0666/0777. No sepolicy. No C. Not a DAC hole. |
| Pass 27 | SKIP landed on `7557043..2ce6daa`. `system.prop` only. No chmod/0666/0777. No sepolicy. No C. SF timing is not a DAC/CVE hole. |
| Pass 28 | SKIP landed on `2ce6daa..2c89f61`. `powerhint.xml` + `init.talkman.power.sh` only. Writes existing cpu-boost sysfs. No chmod/0666/0777. No new sockets. No sepolicy. No C. Not a DAC/CVE hole. |
| Pass 29 | SKIP landed on `2c89f61..76bdeca`. `system.prop` only. No chmod/0666/0777. No sepolicy. No C. SF timing is not a DAC/CVE hole. |
| State | Still draft. Mergeable clean. Not merged. |

The rebase of pull request 6 onto tip `76bdeca` **landed**. Head is `f017afa`. Pass 29 is SKIP. Pass 23 FIX is kept. The pull request is still draft. It is not merged. It is **not** a GPS pass.

These clamps already exist on `lineage-18.1-talkman`. On `lineage-18.1-talkman-hw` they stay in this draft only until merge.

Camera still does not work. Do not mark P0 Working.

---

## History: tip 2c89f61 (A57 1.5 s input boost)

During a Settings fling the A57 cluster sat at 384 MHz for 82 percent of samples. Bullhead cpu-boost only boosts LITTLE (`0:960000`) for 40 ms. `sched_upmigrate` 95 keeps UI threads on A53s.

`init.talkman.power.sh` and `powerhint.xml` Defaults + INTERACTION + LAUNCH:

| Knob | Value |
|---|---|
| `input_boost_freq` | `0:960000 4:1248000 5:1248000` |
| `input_boost_ms` | 1500 |
| `sched_boost_on_input` | Y |

INTERACTION also raises A57 policy min to 1248000 for 1.5 s.

INTERACTIVE_OFF keeps the 40 ms LITTLE-only boost so a screen-off wake does not spin A57s.

Measured (`dumpsys gfxinfo` framestats, GPU already floored at 300 MHz): dequeueBuffer p90 10.6 ms → 0.35 ms and 42 → 0 frames over 16.7 ms in last 120 frames; over two full runs 2.7 percent and 9.2 percent of frames were over budget (all dequeueBuffer waits, render work p90 9.7 ms). 1824000 measured the same as 1248000, so the lower A57 floor is used; without sched boost 8 frames were over budget.

Parent `2ce6daa`. Author archienz.

This is **not** a camera land.

---

## History: tip 2ce6daa (one-vsync SF phase)

This tip is `system.prop` only. No C. No sepolicy. No chmod.

Bullhead 27.6 ms durations presented two 16.67 ms TE periods out. The panel is still 60 Hz. Touch-to-photon drops the extra frame.

| Property | Value |
|---|---|
| `debug.sf.*.sf.duration` | 5500000 (5.5 ms) |
| `debug.sf.*.app.duration` | 11000000 (11 ms) at this tip. Later tip `76bdeca` sets app 15.5 ms. SF stays 5.5 ms. |

Parent `7557043`. Author archienz.

This is **not** a camera land.

---

## History: tip 7557043 (GPU 300 MHz floor)

Measured on RM-1104 kernel #29, `dumpsys gfxinfo` framestats while scrolling Settings.

The 60 Hz WQHD command-mode panel and MDP/HWC composition are fine: 0 missed frames, 0 client composition, present-to-present 16–17 ms.

Adreno 418 sat at 180 MHz with about 60 percent busy. TZ DCVS never ramped it. That cost 12–14 ms of GPU per UI frame. A 300 MHz floor drops that to 7–9 ms.

| File | Change |
|---|---|
| `configs/powerhint.xml` | INTERACTION and LAUNCH hints add Gpu `min_pwrlevel=4` (300 MHz). Defaults `default_pwrlevel=4` so GPU wakes from slumber at 300 MHz. Idle still decays to 180 MHz via `msm-adreno-tz`. |
| `rootdir/etc/init.talkman.power.sh` | `default_pwrlevel` 5→4 to match. |
| `system.prop` | `debug.sf.*.app.duration` 27.6→20.4 ms at this tip. Later tips set one-vsync 5.5 ms SF, then app 11.0 ms, then app 15.5 ms. |

Touch: synaptics S3708 reports at about 113 Hz (median 8.87 ms) already. F01_CTRL0 report-rate bit is accepted but does not change the rate.

Parent `42074ab`. Author archienz.

This is **not** a camera land.

---

## History: tip 42074ab (Cursor workspace bind)

This tip adds Cursor bind files so the Cursor app binds this GitHub repo.

| File | Fact |
|---|---|
| `AGENTS.md` | +9 lines. Points at the talkman device tree and `.cursor/rules/talkman.mdc`. |
| `.cursor/rules/talkman.mdc` | +16 lines. Always-on talkman rules. |

No HAL. No C++. No sepolicy. No init. No XML. No DAC.

This is **not** a camera land. It is **not** hardware.

Parent `f63634f`. Author archienz.

---

## History: tip f63634f (MountAngle 90 / Kernel #28)

This tip is docs and camera XML only. No C. No init. No DAC.

| Item | Fact |
|---|---|
| `MountAngle` | **90** (was 360). HAL1 reported orientation 0 with 360 (`360 % 360`). Rear module is 90. |
| `LaneAssign` | **0x0423** (was 0x4320). Matches DT (RM-1104 CSI0 LN2/LN1/LN3/LN0). |
| Kernel #28 | Snap live preview and stills (claimed / observed). |
| Files | `README.md`, `camera/msm8992_camera.xml`, `changes.md`, `configs/msm8992_camera.xml` |

Parent `a844768`. Author archienz.

Record Kernel #28 preview and stills as **observed**. This is **not** a camera Working pass. Camera stays **Not Working** until `out/qa-*` logs.

---

## History: tip a844768 (cameraserver / thermal-engine)

This tip is init and sepolicy only. No HAL source. No XML. No kernel. No flash.

Drop both `restart cameraserver` lines on `sys.boot_completed=1`:

| File | Change |
|---|---|
| `rootdir/etc/init.talkman.rc` | Drop `restart cameraserver` on `boot_completed`. Keep `start qcamerasvr`. |
| `rootdir/etc/init.talkman.camera.rc` | Drop `restart cameraserver` on `boot_completed`. Keep `start qcamerasvr`. |

The two restarts killed cameraserver twice inside 5 s. Init then applied a 5 s restart backoff. That left no `ICameraService` for about 15 s after boot. Snap in that window got an empty `CameraManager.getCameraIdList()` and failed (`length=0; index=0`).

On this tip, thermal-engine sockets change from `0660 system system` to `0666 system system` (`thermal-send-client`, `thermal-recv-client`, `thermal-recv-passive-client`). That makes `thermal-recv-client` world-writable.

Draft pull request 6 Pass 23 **FIX** sets `thermal-recv-client` to `0660 system camera` (CAF recv-client mode). Send-client and recv-passive-client stay `0666`. See **Draft pull request 6**.

`sepolicy/hal_camera.te` adds `unix_socket_connect(hal_camera, thermal, thermal-engine)` so `hal_camera` can connect to thermal-engine sockets in enforcing mode.

Verified on the tip: `host_init_verifier` passes both rc files. `vendor_sepolicy.cil` builds and contains the `hal_camera` thermal socket / connectto rules.

Files: `rootdir/etc/init.talkman.camera.rc`, `rootdir/etc/init.talkman.rc`, `sepolicy/hal_camera.te`. Parent `1e64790`. Author archienz.

This is **not** a camera Working pass.

---

## History: tip 1e64790 (Clark QCamera2)

Replace the bullhead-derived QCamera2 tree with Moto Clark (Moto X Style, MSM8992) lineage-18.1 `QCamera2` / `mm-image-codec`.

The HAL `cam_intf` ABI (`CAM_INTF_PARM_MAX` **213**) matches the Clark `mm-qcamera-daemon` and `liboemcamera` blobs. That removes the enum skew that made the HAL send a 1x0 `MAX_DIMENSION` and fail iface-ISP linking.

| Item | Fact |
|---|---|
| `device.mk` | Uses `camera.msm8992` + `libmmcamera_interface` / `libmmjpeg_interface` / `libqomx_core`. Drops bullhead `libmm-qcamera` / `mm-qcamera-app` test apps. |
| `QCamera2/Android.mk` | Builds against Clark sources. |
| `QCameraFlash` | Removed with the Clark tree. Torch first-ship stays on liblight. |
| `QCameraStream::putBufs` | Signals the buffer-alloc thread (`cond_signal`) before `pthread_join` (as `releaseBuffs` already does). Without the signal, `BufAllocRoutine` stays blocked in `cond_wait` when start fails, so `put_buf` deadlocks `CAM_stMachine` and hangs cameraserver on every failed preview start. |
| proprietary-files / blobs | Track the Clark camera blob set. Drop bullhead-only camera blobs. |
| XML | CameraId 0 `mot_imx230`. No `FlashName` / `OisName`. Later tip `f63634f` sets `MountAngle` 90 and `LaneAssign` 0x0423. |
| Kernel | No kernel edits. |

Parent `f8b2e89`. Author archienz.

This is **not** a camera Working pass. Camera stays **Not Working** until `out/qa-*` logs.

---

## History: tip f8b2e89 (health gate)

The talkman Health subclass overrides `UpdateHealthInfo()`.

It gates three pinned `bms` values before they leave the HAL:

| Sysfs / field | Gate | When the value fails |
|---|---|---|
| `charge_full` (`batteryFullCharge`) | Reported only when greater than 0 and within 20 percent of design capacity. Fallback design is 3000 mAh BV-T5E if design is off. | Report 0. No substitute value. |
| `cycle_count` (`batteryCycleCount`) | Reported only in 0..4000. | Report 0. |
| `charge_full_design` | Kept when within 20 percent of 3000 mAh (3043000 here). | Report 0. |

Live values stay autodetected on `battery`. After the push, `getHealthInfo_2_1` reports:

| Field | Value |
|---|---|
| level | 100 |
| voltage | 4274 mV |
| status | FULL |
| charge counter | 2998699 |
| `batteryFullCharge` | 0 |
| `batteryCycleCount` | 0 |
| design | 3043000 |

One logcat warning per rejected value. The warning repeats only when the sysfs value changes.

The Settings overlay has **no** consumer of `config_battery*` resources. The HAL gate is where the values are filtered.

Files: `health/HealthImpl.cpp`, `overlay/packages/apps/Settings/res/values/config.xml`. Parent `f65cdcc`. Author archienz.

This is **not** a hardware pass. Do **not** mark P0.1 or P0.2 **Working**.

---

## History: tip f65cdcc (changes.md move)

This tip is docs only.

`README.md` keeps Purpose, Progress, and a community battery comparison.

The old Changes list is `changes.md`.

Files: `README.md`, `changes.md` (added), `docs/index.md`. Parent `dcdd7a4`. Author archienz.

This is **not** a hardware pass.

---

## History: tip dcdd7a4 (battery / USB observed)

This tip is docs only. It records observations on this telephone.

P0.1 claim: live `dumpsys` percent and voltage. That is **not** a hardcoded 50 percent.

P0.2 claim: USB cable charge is online (SDP 5 V / 500 mA, status Full). Qi pad is not tested. There is no inline USB meter.

Those claims stay observations. They are **not** marked Working. `out/qa-*` logs are not in that fold.

---

## History: tip b0fe90d (CameraId 0 + Snap ISP 0x0)

This tip is docs only. It records measured camera state on the telephone.

CCI1 ACK is write **0x20** / chip **0x0230** (measured). `dumpsys` shows **1** camera. `openCamera` returns rc **0**.

Snap `startPreview` fails. ISP sensor resolution is **0x0**.

Camera stays **Not Working** until `out/qa-*` logs.

---

## History: tip 8ce324b (imx377 probe + blob ban list)

This tip records why the daemon probed bullhead `imx377` while the XML said `mot_imx230`. It also fixes the extract blob ban list.

`sensor_init_probe()` in `libmmcamera2_sensor_modules.so` walks a sensor list compiled into that blob. It does **not** read the XML. `mot_imx230` is not in that list. The blob opens `libmmcamera_<name>.so` for each compiled name.

The vendor tree now installs the Clark library a second time as `libmmcamera_imx230.so`. That is the only rear name the blob will open. The kernel name still comes from `sensor_slave_info` in the library, so the slot probes as `mot_imx230`.

`setup-makefiles.sh` allows `vendor/lib/libmmcamera_imx230.so` as a derived dest. `proprietary-files.txt` must not list that path. No dump has that path.

`extract-files.sh` no longer bans `libgoog_eis_armeabi-v7a.so` and `libgoog_rownr.so`. Those are `dlopen()` names in `libmmcamera2_imglib_modules.so` and `libmmcamera_imglib.so`. The ban on `lc898212xd` is now `libactuator_lc898212xd` only, so a Clark `libactuator_mot_lc898212xd.so` is still allowed.

This is **not** a camera Working pass.

---

## History: tip c6844a7 (install docs, Pages, VINTF de-dupe)

Tip `c6844a7` expands the install procedure, first-boot findings, and GitHub Pages docs.

In range `025df9c..c6844a7`:

| Commit | Fact |
|---|---|
| `3925712` | Adds `docs/INSTALL.md`. Drops duplicate health / power / vibrator HALs from `manifest.xml` (`DEVICE_MANIFEST_FILE`). Those HALs stay on `vintf_fragments`. |
| `39c8eb2` | Adds `docs/_config.yml` for GitHub Pages `/docs`. |
| `c6844a7` | Expands `docs/INSTALL.md`, `docs/index.md`, and `README.md`. |

`docs/INSTALL.md` `chmod 640` is operator prose. It is not init. The VINTF de-dupe is packaging. It is **not** a HAL pass.

---

## History: tip 025df9c (Steam Deck zip Progress)

An unofficial zip exists on the Steam Deck build tree: `out/target/product/talkman/lineage-18.1-20260901-UNOFFICIAL-talkman.zip`.

That is Progress. That is **not** a hardware pass.

`boot.img` also exists on that build tree. There is no official LineageOS zip.

---

## History: tip 6da0d97 (e2fsdroid /bt_firmware)

`target_files` failed: `set_selinux_xattr` searched for `/bt_firmware`.

`BOARD_ROOT_EXTRA_FOLDERS` creates that ramdisk directory for Rome `libbt-vendor`.

Tip `6da0d97a9c3640faf9e0f2b377987603e527188b` adds `/bt_firmware(/.*)?` as `firmware_file` in `sepolicy/file_contexts`. RM-1104 only.

This is a packaging label. It is **not** a Bluetooth pass. SELinux stays permissive.

---

## History: tip 1387c66 (recovery.fstab under system/etc)

`rsync` 3.4.1 refuses to replace `recovery/root/etc` (a real directory) with the ramdisk symlink `etc` → `/system/etc`.

| Commit | File | Fact |
|---|---|---|
| `96713de` | `recovery/root/etc/recovery.fstab` | Delete. Stop shipping the recovery overlay `/etc` copy. |
| `1387c66` | `device.mk` | `PRODUCT_COPY_FILES` dest is now `recovery/root/system/etc/recovery.fstab`. |

RM-1104 only. This is a packaging path fix. It is **not** a recovery pass.

---

## History: tip cd18318 (NFC host_init_verifier)

Android 11 `host_init_verifier` rejects `/` in trigger names.

The old stanza `on device-added-/dev/pn547` in `nfc/init.talkman.nfc.rc` used `/` in the trigger name. `mka bacon` failed when the build copied that file.

Tip `cd18318881bbb3a6c6b2d779a5554efce474c76c` drops that trigger. The change is in `nfc/init.talkman.nfc.rc` only.

| Item | Fact |
|---|---|
| Removed trigger | `on device-added-/dev/pn547` |
| Product | RM-1104 only |
| ueventd | `rootdir/etc/ueventd.talkman.rc` keeps `/dev/pn547` as `0660 nfc nfc` |
| `on boot` | Still `chmod` / `chown` / `restorecon` on `/dev/pn547`. Still makes symlink `/dev/pn54x`. Still `chmod` / `chown` on `/dev/pn54x`. |
| HAL path | `nfc_nci.msm8992.so` still opens `/dev/pn54x` if `NXP_NFC_DEV_NODE` is rejected |

This is a host verifier fix. It is **not** an NFC pass.

---

## History: parent tip 31a5359

These notes stay true on `76bdeca`. They landed in `31a5359909e07703770492861d00415a0b619733` (`talkman: health HAL, vendor GPS loc, GPIO torch, CAF compile patches`).

Tip `f8b2e89` then gates the three pinned `bms` values in `UpdateHealthInfo()`. See **History: tip f8b2e89 (health gate)**.

Tip `1e64790` then switches QCamera2 to Clark. See **History: tip 1e64790 (Clark QCamera2)**.

Tip `a844768` then drops the double `restart cameraserver` and opens thermal-engine sockets to the HAL. See **History: tip a844768 (cameraserver / thermal-engine)**.

Tip `f63634f` then records Kernel #28 rear IMX230 preview docs and sets `MountAngle` 90 / `LaneAssign` 0x0423. See **History: tip f63634f**.

Tip `42074ab` then adds Cursor bind files. See **History: tip 42074ab**.

Tip `7557043` then sets a GPU 300 MHz floor. See **History: tip 7557043**.

Tip `2ce6daa` then sets one-vsync SF phase (5.5 ms SF / 11 ms app). See **History: tip 2ce6daa**.

Tip `2c89f61` then sets a 1.5 s A57 input boost with HMP sched boost. See **History: tip 2c89f61**.

Tip `76bdeca` then sets app duration 15.5 ms. SF stays 5.5 ms. See **App duration 15.5 ms (this tip)**.

### Health HAL

Package name in the tree description: `android.hardware.health@2.1-impl.talkman`.

Soong module name: `android.hardware.health@2.1-impl-talkman`.

Source: `health/HealthImpl.cpp`. Blueprint: `health/Android.bp`.

The module stem is `android.hardware.health@2.0-impl-2.1-talkman`. The module overrides stock `android.hardware.health@2.1-impl`. Recovery keeps `android.hardware.health@2.0-impl-default`.

Talkman splits the pack across two `power_supply` nodes:

| Node | Driver | Type |
|---|---|---|
| `bms` | `qpnp-fg.c` | `POWER_SUPPLY_TYPE_BMS` |
| `battery` | `qpnp-smbcharger` | `POWER_SUPPLY_TYPE_BATTERY` |

`BatteryMonitor::readPowerSupplyType()` has no `BMS` entry. The monitor skips `bms`. Autodetect then uses `battery`. The smbcharger `battery` node does not export `CHARGE_FULL`, `CHARGE_FULL_DESIGN`, or `CYCLE_COUNT`. Those properties live on `fg_power_props[]` only. Stock Health then reports 0 and logs `<name> not found`.

`HealthImpl.cpp` pins the fuel-gauge paths **before** `BatteryMonitor::init()`:

| Config field | Sysfs path |
|---|---|
| `batteryFullChargePath` | `/sys/class/power_supply/bms/charge_full` |
| `batteryFullChargeDesignCapacityUahPath` | `/sys/class/power_supply/bms/charge_full_design` |
| `batteryCycleCountPath` | `/sys/class/power_supply/bms/cycle_count` |
| `energyCounter` | `TalkmanEnergyCounter` |

`TalkmanEnergyCounter` reads `bms/charge_now` (uAh) and `bms/voltage_now` (uV). Remaining energy is `(charge_now × voltage_now) / 1000` nWh. If `charge_now` is 0 (no completed charge cycle against the `microsoft_bvt5e_3000mah` profile), the function returns an error. It does not report 0 nWh.

Capacity, status, health, voltage, current, temperature, and `charge_counter` still come from `battery` (smbcharger proxy). There is **no** hardcoded 50 percent.

`batteryCapacityLevel` and `batteryChargeTimeToFullNowSeconds` stay at the `UNSUPPORTED` default. CAF 3.10 `qpnp-fg` has no sysfs for those fields. A synthetic `CRITICAL` level would shut the telephone down at 5 percent.

Kernel patch `patches/0001-msm8992-chi-bind-batterydata-to-pmi8994_fg.patch` binds `talkman_batterydata` to `pmi8994_fg`. Apply that patch on `kernel/mmo/msm8994`. This pin is source only. It is not a Battery UI pass.

### GPS loc vendor

CAF loc modules install to **vendor**:

| Module | Role |
|---|---|
| `libgps.utils` | Loc utilities |
| `libloc_core` | Loc core |
| `libloc_eng` | Loc engine |
| `gps.msm8992` | GPS hardware module |

Patch `patches/0003-gps-msm8994-loc-modules-vendor.patch` sets `LOCAL_PROPRIETARY_MODULE := true` on those CAF msm8994 makefiles. A vendor GNSS process cannot `dlopen` `/system/lib*/hw`.

Blobs `libloc_api_v02` and `libloc_ds_api` copy to `/vendor/lib` and `/vendor/lib64` (`proprietary-files.txt`, `extract-files.sh`). `gps.msm8992` `dlopen`s `libloc_api_v02.so`.

`init.talkman.gps.rc` sets mode 0644 on these files under `/system/etc` (the path the blobs open; `/etc` is a symlink to `/system/etc`):

- `izat.conf`
- `sap.conf`
- `flp.conf`
- `lowi.conf`

The same init file also sets mode 0644 on `/system/etc/gps.conf` and `/vendor/etc/gps.conf`.

GNSS HIDL package: `android.hardware.gnss@1.0-impl.talkman`.

GPS is **Not Working**. There is no GPSTest log with `numSvs` more than 0. A packed installer `modem.img` note exists (`dc847d5`, about 70 MiB, MBA/MPSS). MPSS / modem bring-up is still missing for a GPS pass.

### GPIO torch stays on liblight

Light HIDL 2.0 has **no** `Type::FLASHLIGHT` enum.

`lights/Light.cpp` writes `lcd-backlight` and RGB sysfs only. Torch is not on that HIDL path.

The Clark QCamera2 tree does **not** ship `QCameraFlash`. Torch first-ship stays on liblight `LIGHT_ID_FLASHLIGHT` (`liblight/lights.c`, `set_light_flashlight`).

Torch GPIO is **12** (schematic `TORCH_EN`, MSM ball BH5, flash driver IC N1400 TORCH pin).

liblight writes:

- `/sys/class/leds/led:flash_torch/brightness`
- `/sys/class/leds/led:torch_0/brightness`

This document does **not** change `lights.c`. Do not edit `lights.c` for this first-ship record.

The I2C address of N1400 is not on the drawing. Do not invent `qcom,slave-id`.

### CAF patches and build state

CAF display and media compile fixes live in `patches/`.

| File | Tree | Fact |
|---|---|---|
| `0004-media-msm8974-gralloc-c2d-includes.patch` | `hardware/qcom/media` | msm8992 OMX adds msm8994 `gralloc_priv.h` / `c2d2.h` includes |
| `0005-display-msm8994-gnu17-hwc-werror.patch` | `hardware/qcom/display` | msm8994 HWC / gnu++17 Clang `-Werror` compile fix |

Other patches in the same directory:

| File | Tree | Fact |
|---|---|---|
| `0001-msm8992-chi-bind-batterydata-to-pmi8994_fg.patch` | `kernel/mmo/msm8994` | Bind `talkman_batterydata` to `pmi8994_fg` |
| `0002-dts-talkman-camera-usbc-charger-audio.patch` | `kernel/mmo/msm8994` | Camera / USB-C / charger / audio DT |
| `0003-gps-msm8994-loc-modules-vendor.patch` | `hardware/qcom/gps` | CAF loc modules install to vendor |

`patches/README.md` says: apply from the matching tree root. Do not push those trees to LineageOS.

An unofficial zip exists on the Steam Deck. That zip is **not** a hardware pass.

---

## Still missing

These items are still missing at tip `76bdeca`:

| Item | Fact |
|---|---|
| P0.1 / P0.2 `out/qa-*` | Not in this fold. Observed dumpsys / USB cable facts stay observations from `dcdd7a4`. |
| P0.4 `out/qa-*` | Not in this fold. Kernel #28 Snap preview and stills stay observations from `f63634f`. Camera stays Not Working. |
| CCI ACK | **Measured.** CCI1 write **0x20** / chip **0x0230**. |
| OIS `.so` | No `libmmcamera_ois_bu24210.so` in the dumps. OIS `.kar` files are in `COPY_FILES`. CAF `msm_ois` does not `request_firmware` those `.kar` files. |
| MPSS / modem bring-up | Still missing for a GPS pass. |

Camera is **Not Working**. GPS is **Not Working**. Do not invent `qcom,slave-id`. Dual SIM is out of scope.

---

## Other locked facts (not Working claims)

| Item | Fact |
|---|---|
| Dual SIM | Out of scope. Schematic is RM-1104 board **4VM_08r** only. |
| SELinux | Stays permissive (`BoardConfig.mk`: `androidboot.selinux=permissive`) |
| OTA assert | `talkman` only (`TARGET_OTA_ASSERT_DEVICE := talkman`). No bullhead. No angler. |

---

## What you must not do

- Do not mark P0 Working without `out/qa-*` logs from the telephone.
- Do not invent `qcom,slave-id`.
- Do not return a fake battery capacity of 50 percent.
- Do not edit camera XML, mixer, `lights.c`, rild, health C++, GNSS C++, NFC C++, or any C++ for this document.
- Do not edit `README.md`, `system.prop`, or powerhint for this document.
- Do not push `lineage-18.1-talkman-hw` tip from a `cursor/*` branch.
- Do not treat Dual SIM as talkman.
