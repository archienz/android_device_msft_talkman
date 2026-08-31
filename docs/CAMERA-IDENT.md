# Talkman camera ident — CANDIDATE only

Date: 2026-08-31. Scope: docs. No DT change. No XML CameraId 1.

## Status

These values are **EpicLPer lab ident**. Treat them as **CANDIDATE**.
They are not our CCI scan. They are not DT.

Do **not** write `qcom,slave-id` into device tree.
Do **not** enable CameraId 1.
Front SMIA work is a **LIVE** agent. Do not edit `FRONT-CAMERA.md`.

Our rear CCI node still uses `qcom,cci-master = <0>`. His Hill ident is **CCI1**. That conflict is **open**. Resolve with `talkman-cci-scan` on a talkman. Do not pick a master by guess.

## Candidate table (not DT)

| Item | EpicLPer lab | Ours now | Rule |
|---|---|---|---|
| Hill sensor 8-bit write | `0x20` (7-bit `0x10`) | No slave-id in DT | CANDIDATE. Scan first. |
| OIS 8-bit write | `0x7c` | `qcom,ois@0` `reg = <0x0>` only | CANDIDATE. Scan first. |
| WP SID remap | SMIA `0x0107` → 8-bit `0x22` | HAL would stay on `0x20` | CANDIDATE. Half-apply causes NACK. Do not invent the remap in DT. |
| CCI master | Hill on **CCI1** | `qcom,cci-master = <0>` | Open. Scan both masters. |
| Front CameraId 1 | His dump `0x2140` when enabled | No CameraId 1 XML | Leave off. Front SMIA agent is LIVE. |

Source: EpicLPer `Lumia950-Camera-Bringup` `notes/handoff.md`. Compare file: `docs/EPICLPER-COMPARE.md`.

## What this is not

This file is **not** a slave-id. It is **not** a sensor probe pass.
CCI scan has **never** run on our talkman.

Do **not** copy `qcom,slave-id = <0x00 0x20 …>` or `<0x00 0x22 …>` into `talkman-camera.dtsi`.
Do **not** Magisk-bind a random `imx230` HAL.
Do **not** ship CSID test-generator as camera.

## Next

1. Run `echo 1 > /sys/kernel/debug/talkman-cci-scan/scan`.
2. Record ACK on CCI0 and CCI1 for `0x20`, `0x22`, `0x7c`.
3. Read Sony SMIA `0x0016`/`0x0017` only on an ACK.
4. Then — and only then — write `qcom,slave-id` and pick `cci-master`.
