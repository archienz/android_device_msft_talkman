# Talkman camera ident

Date: 2026-09-02 (rear + front CCI). Scope: docs. No XML CameraId 1. No `CONFIG_MSM_OIS`.

## Status

CCI scan ran on this RM-1104. Rear Snap preview and stills work (kernel `#29`). Front is measured and is **not** a CameraId. Dual SIM **RM-1118** / **4VM_08d** is ignored.

Do **not** invent a front `qcom,slave-id`. Do not bind `lc898212xd`. Do not ship CSID test-generator as camera.

## Measured table

| Item | Measured on this telephone | Rule |
|---|---|---|
| Rear CCI master | **1** (GPIO 19/20) | Bus index |
| Rear write / chip | **0x20** / **0x0230** at SMIA `0x0016` | IMX230. DT `qcom,slave-id` is this measurement |
| Rear module header | `0xEACA`, manufacturer **0x0A**, rev major **5** | Windows DCC **10454105** (Karma `.kar`) |
| Companion on CCI1 | sid **0x3e** write **0x7c**, model `0x6500` | Mitsumi BU24210. Do not enable CAF OIS |
| Master 0 sid 0x30 | chip **0x0250** | Not the rear array |
| Front CCI master | **0** (GPIO 17/18), MCLK2 GPIO 15, L17, reset GPIO **104** | Scanner must release reset or the sensor NAKs |
| Front write / module | **0x20** / `MODEL_ID` **0x2140**, manufacturer **0x0A** | Nokia/Microsoft **Ducati** (DCC `0A214000`). Not IMX214 |
| Front die | `SENSOR_MODEL_ID` **0x03BB**, sensor mfr `0x0019`=`0x01`, 2600×1952 RAW10 | Part not proven. `0x2016` = `0x0000` (HM5040 not confirmed) |
| Front CameraId 1 | XML off | Leave off until a real `libmmcamera_*` exists for this die |
| NFC GPIO | IRQ 29 / VEN 30 / DWL 94 | Not camera |

## Front (Ducati)

EpicLPer `0x2140` is the **module** id. This telephone scanned the same value on CCI0 after GPIO 104 was released.

- Not Sony IMX214 (die would be `0x0214`, 13 MP).
- Not OV5693 / IMX230.
- Himax HM5040 is a candidate only (MediaTek chip-id `0x03BB`). Confirmation read at Himax `0x2016` returned **0**. Do not name HM5040 in DT.

Logs: `out/qa-cam-20260902/FRONT-SENSOR-ID.md` (not in Git).

## Rear AF / OIS (BU24210)

Windows SMIApp loads `.kar` through DTI registers `0x0581` / `0x0584`, then OIS_INIT `0x0550`. On this telephone the DTI pages ACK and the first `0x0550` write kills the chip (NAK, off bus). HAL reports `focus-mode: fixed` until a 0x7c driver exists.

Protocol notes: `out/qa-ois-re/BU24210-PROTOCOL.md` (not in Git).
