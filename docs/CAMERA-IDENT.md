# Talkman camera ident — CANDIDATE only

Date: 2026-08-31. Scope: docs. No slave-id. No XML CameraId 1.

## Status

These values are **EpicLPer lab ident** plus **RM-1104 schematic 4VM_08r**.
Treat 7-bit SIDs as **CANDIDATE**. They are not our CCI scan.

Do **not** write `qcom,slave-id` into device tree.
Do **not** enable CameraId 1.
Front SMIA work is a **LIVE** agent. Do not edit `FRONT-CAMERA.md`.

**Rear CCI master 1 is schematic + lab, not a slave-id.**
RM-1104 sheet 3 (`page-02.png`) routes rear I2C on `CCI1_I2C_CLK` / `CCI1_I2C_DATA`.
EpicLPer Hill ident used **CCI1**. DT rear/actuator/OIS use `qcom,cci-master = <1>`.
That bus index is **not** `qcom,slave-id`. Scan still decides ACK addresses.

Dual SIM **RM-1118** / board **4VM_08d** is **ignored**. Do not copy UIM2 / Dual SIM finder sheets.

NFC GPIOs **match** schematic and DT: IRQ **29**, VEN **30**, FW-download **94**. Not camera. Recorded here so CAMERA-IDENT does not steal those pins.

## Candidate table (not slave-id)

| Item | Schematic + EpicLPer lab | Ours now | Rule |
|---|---|---|---|
| Rear CCI master | **CCI1** (RM-1104 4VM_08r + Hill) | `qcom,cci-master = <1>` on rear/actuator/OIS | Bus index only. **Not** a slave-id. |
| Hill sensor 8-bit write | `0x20` (7-bit `0x10`) | No slave-id in DT | CANDIDATE. Scan first. |
| OIS 8-bit write | `0x7c` | `qcom,ois@0` `reg = <0x0>` only | CANDIDATE. Scan first. |
| WP SID remap | SMIA `0x0107` → 8-bit `0x22` | HAL would stay on `0x20` | CANDIDATE. Half-apply causes NACK. Do not invent the remap in DT. |
| Front CameraId 1 | His dump `0x2140` when enabled | No CameraId 1 XML | Leave off. Front SMIA agent is LIVE. |
| NFC GPIO | IRQ 29 / VEN 30 / DWL 94 | Same in `nfc.dtsi` | Match. Not Dual SIM. Not CCI. |
| Dual SIM | RM-1118 / 4VM_08d | Ignored | Do not copy. |

Source: EpicLPer `Lumia950-Camera-Bringup` `notes/handoff.md`; `docs/hardware/SCHEMATIC-RM-1104.md`; `docs/nfc-pn547.md`. Compare: `docs/EPICLPER-COMPARE.md`.

## What this is not

This file is **not** a slave-id. CCI master 1 is **not** a slave-id.
It is **not** a sensor probe pass.
CCI scan has **never** run on our talkman (`out/qa-camera` is empty on purpose).

Do **not** copy `qcom,slave-id = <0x00 0x20 …>` or `<0x00 0x22 …>` into `talkman-camera.dtsi`.
Do **not** Magisk-bind a random `imx230` HAL.
Do **not** ship CSID test-generator as camera.

## Next

1. Run `echo 1 > /sys/kernel/debug/talkman-cci-scan/scan`.
2. Record ACK on **CCI1** (and CCI0 for front) for `0x20`, `0x22`, `0x7c`.
3. Read Sony SMIA `0x0016`/`0x0017` only on an ACK.
4. Then — and only then — write `qcom,slave-id`. Do not treat CCI master 1 as that write.
