# Talkman camera ident

Date: 2026-09-02. Scope: docs. No XML CameraId 1. No `CONFIG_MSM_OIS`.

## Status

CCI scan **did** run on this RM-1104 (kernel `#17` / `#21` logs, not in Git).
Rear pixel array is on **CCI master 1**, 8-bit write **0x20**, Sony chip **0x0230**
at **0x0016**. That is IMX230. Kernel DT `qcom,slave-id = <0x20 0x0016 0x0230>`
is that measurement.

Do **not** enable CameraId 1. Dual SIM **RM-1118** / **4VM_08d** is ignored.

## Measured table

| Item | Measured on this telephone | Rule |
|---|---|---|
| Rear CCI master | **1** (GPIO 19/20) | Bus index |
| Rear write / chip | **0x20** / **0x0230** | IMX230. Not invented |
| Companion on CCI1 | sid **0x3e** write **0x7c** | Present. Do not enable OIS |
| Master 0 sid 0x30 | chip **0x0250** | Not the rear array |
| Front CameraId 1 | unnamed SMIA, XML off | Leave off |
| NFC GPIO | IRQ 29 / VEN 30 / DWL 94 | Not camera |

## What this is not

It is **not** a JPEG pass. Snap preview still fails (ISP `0x0` resolution).
Do **not** ship CSID test-generator as camera.
3. Read Sony SMIA `0x0016`/`0x0017` only on an ACK.
4. Then — and only then — write `qcom,slave-id`. Do not treat CCI master 1 as that write.
