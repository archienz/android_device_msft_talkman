# EpicLPer vs our current trees (2026-08-31)

Compared against **this workspace** (`mirrors/android_kernel_mmo_msm8994` + `mirrors/android_device_msft_talkman`), not community origin HEAD and not EpicLPer Magisk daily images.

Sources: [Lumia950-Camera-Bringup](https://github.com/EpicLPer/Lumia950-Camera-Bringup) `notes/handoff.md`, [Lumia950-NFC-Fix](https://github.com/EpicLPer/Lumia950-NFC-Fix), [Lumia950-Audio-Fix](https://github.com/EpicLPer/Lumia950-Audio-Fix).

Do not copy a path because it is easier. Pink CSID test-generator preview is not a camera.

## Camera

| Topic | Ours (now) | EpicLPer | Verdict |
|---|---|---|---|
| Stack | QCamera2 MSMB, `qcom,camera`, `mot_imx230` | `qcom,smia65pp` + delayed ident | **Keep ours** for the ROM. His HAL1 “preview” is CSID TG, not live CSI. |
| Rear name | `mot_imx230` | qcamera name `imx230` | Same Sony chip. Clark `libmmcamera_mot_imx230.so` matches MSMB. Do not Magisk-bind a random `imx230` over `/sdcard`. |
| Slave ID | **None.** CCI scan debugfs | Lab ident Hill **8-bit `0x20`**, later WP `0x0107` → **`0x22`**; OIS **`0x7c`** | His IDs are **lab measurements**, not guesses. Still do **not** write `qcom,slave-id` until **our** CCI scan confirms. `0x0107` remaps SID; HAL stuck on `0x20` NACKs. |
| CCI master | `qcom,cci-master = <0>` | Hill on **CCI1** | **Open.** ACPI vs his live ident disagree. Resolve with talkman-cci-scan, not a coin flip. |
| LVS1 1.8 V | `cam_vio` is in `qcom,cam-vreg-name` | Never put LVS1 in cam vreg list; enable and hold (shared VIO). Nested `sensor_power_up` at CCI populate **bootlooped** | **His failure list is stronger.** Next kernel DT pass: keep LVS1 on, stop sequencing it as a camera vreg. Do not copy smia65pp. |
| CSI | lane `0x4320` / mask `0x1F` | Same WP map; live CSI **uncorrectable ECC** after TG-off | Same PHY map. His ECC means **neither** tree has a working JPEG. TG-off daily kernels freeze UI. Do not ship TG. |
| Front | unnamed `qcom,camera@1` | ident `0x2140` when enabled; not started | Document `0x2140` as **his** dump. Do not add CameraId 1 XML until we scan. |

## NFC

| Topic | Ours | EpicLPer | Verdict |
|---|---|---|---|
| Chip | PN547 `/dev/pn547`, I2C6, WOA fw | Same 0x28, nq-nci | Same hardware. |
| Kernel | `nfc.dtsi` `nxp,pn547` + `nq-nci.c` VEN pulse without eSE | Patch: create node, BBCLK2, 250 ms I2C timeout, no `read_mutex` across IRQ | **Overlap.** We already have VEN-off without eSE. Still **diff his patch vs our `nq-nci.c`** for timeout/mutex — take those if ours lacks them. Do not Magisk. |
| Userspace | `init.talkman.nfc.rc`, sepolicy, `libnfc-*.conf`, WOA `libpn547_fw` | Optional Classic NDEF conf; Magisk-free kernel flash | **Keep our userspace.** Optional Classic keys only if we want NDEF URLs. |

## Audio

| Topic | Ours | EpicLPer | Verdict |
|---|---|---|---|
| Amp | TAS2553, `CONFIG_SND_SOC_TAS2552`, QUAT_MI2S in `msm8994.c` + `audio_platform_info.xml` | Same chip, kernel branch + mixer Magisk | **Kernel codec is already in our tree.** |
| Routing | ACDB, policy, AOSP volumes, QUAT_MI2S backends | mixer_paths Magisk; earpiece still on speaker; ACDB not init | **Keep our userspace.** It is the ROM end-state he describes. Mixer leftover agent still LIVE — finish that, do not Magisk. |
| Gain | (DT PGA if present) | 11 dB default to avoid brownout | **Take 11 dB if our DT is still 15 dB.** That is a measured PMIC brownout, not an easy stub. |

## Do not take

- CSID test generator as “working camera”
- Magisk overlay as the product
- Invented or half-applied `0x0107` SID switch
- snaccy `lumia/camera.dtsi` rail name swap (he says it is wrong)

## Next (best, not easy)

1. CCI scan on the phone. Compare ACKs to his `0x20` / `0x7c` / CCI1.
2. LVS1 always-on; drop it from camera vreg seq if still sequenced.
3. Byte-diff `nq-nci.c` vs NFC-Fix patch 0001.
4. Check TAS `pga-gain` vs 0x12 (11 dB).
5. JPEG still blocked on live CSI ECC until new evidence (scope / Sharp analog).
