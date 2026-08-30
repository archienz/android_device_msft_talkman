# talkman camera

This document is for the Lumia 950.
The device codename is talkman.
The SoC is MSM8992 (Snapdragon 808).
This document is not for the Lumia 950 XL.
The Lumia 950 XL codename is cityman.
The cityman SoC is MSM8994.
Do not use cityman camera procedures for talkman.
Do not use HARDWARE.CAMERA.MMO_8994.
Do not use IMX377 or OV5693 chromatix.
Do not invent a sensor id.

The LineageOS 18.1 HIDL skeleton lives in [camera-smiapp/](../camera-smiapp/).
That stub is not the live `camera.provider`.
It does not stream frames.

## Stock Windows 10 Mobile camera stack

Treat these as given.

Userspace is SMIApp plus Icaros ESP.
Flash and lamp are an RGB lamp through `qccamflash8992` and ACPI `QCOM244B`.
The lamp is not xenon.

### ACPI IDs (talkman / MSM8992)

| ACPI ID   | Role                         |
|-----------|------------------------------|
| QCOM2432  | ISP                          |
| QCOM2434  | rear SMIApp                  |
| QCOM2439  | front                        |
| QCOM244B  | flash / RGB lamp             |
| QCOM245E  | platform                     |

### Public driver pack

The public pack is WOA-Project Lumia-Drivers `HARDWARE.CAMERA.MMO_8992.zip` (Icaros ESP camera drivers).
Do not unpack that zip into this tree.
Do not vendor Icaros firmware bytes, DPP `.dcc` calibration, or chromatix `.so` blobs into this tree.
Do not use `HARDWARE.CAMERA.MMO_8994.zip`. That pack is cityman.

## Sourced CSI pairing (talkman MSM8992 only)

These pairings are sourced. Document them. Do not turn them into a live DT in this repository.

- Rear: CSID0 + CSIPHY0
- Front: CSID2 + CSIPHY2
- Rear CSID0 GPIO 92 and GPIO 91 are sourced GPIOs. Cite them as sourced GPIOs. They are not a lane map.

## Unknown. Do not invent

No I2C slave addresses are public.
Do not invent I2C `0x6c` or any other I2C address.

No CSI lane map is public.
Do not invent lane counts, lane maps, clock rates, or regulator names.

GPIO 13 is not a public MCLK from ACPI CAMP.
Do not claim GPIO 13 is MCLK.

Ducati / QDSP camera firmware is unproven.
Do not enable it.
Do not stub it as present.

Do not invent IMX377, OV5693, or any chromatix sensor id.

## Torch (already owned)

Harmony `torch.dtsi` (mmo kernel, not mainline) claims `gpio-leds` `led::flash_torch` on `msm_gpio` 12.
The lights HAL already writes 0 or 255 to `/sys/class/leds/led::flash_torch/brightness`.
CAMP._CRS has GPIO 12 unlabeled. That node is not proven as camera flash from ACPI.

Torch stays with the existing Harmony DT and the lights HAL.
Do not add a second torch path.
Do not add a camera flash DT from GPIO 12.
Do not implement a Quick Settings torch HIDL.
A QS torch HIDL waits on a real `camera.provider`.

## Kernel camera DT

The mmo kernel already packs `talkman-camera.dtsi`.
That fragment is DISABLED.
Do not enable it from this device tree.
Do not add a second enabled camera DT in this repository.
Device-tree SMIApp stubs stay disabled.

This repository is `android_device_msft_talkman` only.
Do not push `android_kernel_mmo_msm8994`.

## Leftover QCamera2

`camera/QCamera2` (plus `camera/mm-image-codec` and the `camera/Android.mk` wiring) is a bullhead path.
Plan: retire.
Do not delete it in this change.
Do not rewrite it in this change.
Do not replace it in `PRODUCT_PACKAGES`.
Do not replace it in the live device VINTF manifest (`manifest.xml`).
The live provider stays `android.hardware.camera.provider@2.4` passthrough instance `legacy/0`.

## HIDL skeleton

`camera-smiapp/` is a LineageOS 18.1 `android.hardware.camera.provider@2.4` stub.
It compiles as its own Soong module.
`getCameraIdList` returns an empty list.
Open requests return HIDL `ILLEGAL_ARGUMENT` (no device). That is the HIDL equivalent of framework `ERROR_NOT_AVAILABLE`.
The stub does not program CSI.
The stub does not stream frames.
The stub is not installed as the live `camera.provider`.
The optional VINTF fragment in that directory is disabled and is not listed in the live device manifest.

## Next steps (blocked)

These steps stay blocked until real Icaros / SMIApp firmware and a DPP dump exist.

1. Keep leftover QCamera2 as the live leftover path until a real provider exists.
2. Do not enable `talkman-camera.dtsi`.
3. Do not enable the `camera-smiapp` VINTF fragment.
4. Do not implement QS torch HIDL.
5. When firmware exists: wire SMIApp / Icaros to a real `camera.provider`, then retire leftover QCamera2.
6. I2C addresses, lane maps, clocks, and regulators stay unknown until a public source or a device dump provides them.
