# talkman SMIApp camera.provider stub

LineageOS 18.1 `android.hardware.camera.provider@2.4` skeleton for talkman (Lumia 950, MSM8992).
This is not cityman. This is not MSM8994. This is not `HARDWARE.CAMERA.MMO_8994`.

Full hardware facts and bans: [docs/CAMERA.md](../docs/CAMERA.md).

## What this module is

`android.hardware.camera.provider@2.4-service.talkman-smiapp` is a binderized HIDL 2.4 `ICameraProvider` that compiles without Icaros firmware.

- `getCameraIdList` returns an empty list.
- `getCameraDeviceInterface_V1_x` and `getCameraDeviceInterface_V3_x` return `ILLEGAL_ARGUMENT` and a null device.
- `isSetTorchModeSupported` returns false. Torch stays on Harmony `led::flash_torch` (SoC GPIO 12) via the lights HAL. This stub is not a QS torch HIDL.
- The process does not program CSI, clocks, or regulators.
- The process does not stream frames.
- Empty camera list / framework `ERROR_NOT_AVAILABLE` is the correct user-visible result until Icaros / SMIApp firmware exists.

## What this module is not

It is not the live device `camera.provider`.
The live VINTF entry in `manifest.xml` stays leftover QCamera2 passthrough `legacy/0`.
Do not add this module to `PRODUCT_PACKAGES` as a replacement for `camera.msm8992` or `android.hardware.camera.provider@2.4-impl`.
The init `.rc` is `disabled`.
The VINTF fragment in this directory is a disabled reference. It is not installed. It is not listed in `Android.bp` `vintf_fragments`.

Do not copy cityman QCamera2, bullhead/angler camera HAL, IMX377, OV5693, or chromatix into this directory.
Do not vendor Icaros firmware, DPP `.dcc`, or chromatix `.so` here.

## Sourced talkman facts used by this skeleton

ACPI: QCOM2432 ISP, QCOM2434 rear SMIApp, QCOM2439 front, QCOM244B RGB lamp, QCOM245E platform.
Public pack: WOA-Project Lumia-Drivers `HARDWARE.CAMERA.MMO_8992.zip`. Do not unpack it here.

CSI pairing (sourced, talkman MSM8992 only):

- Rear: CSID0 + CSIPHY0
- Front: CSID2 + CSIPHY2
- Rear CSID0 GPIO 92 and GPIO 91 are sourced GPIOs, not a lane map

Unknown (do not invent): I2C slave addresses, CSI lane maps, clock rates, regulator names, GPIO 13 as MCLK, Ducati / QDSP camera firmware, IMX377, OV5693.

Kernel `talkman-camera.dtsi` is already packed and DISABLED. Do not enable it. Do not add a second camera DT here.

## Build

In a LineageOS 18.1 tree with this device tree at `device/msft/talkman`:

```
m android.hardware.camera.provider@2.4-service.talkman-smiapp
```

The module is Soong-visible from `camera-smiapp/Android.bp`.
It is not on the shipped image unless a later change adds it as an extra package without dropping leftover QCamera2 and without replacing the live VINTF `legacy/0` instance.
