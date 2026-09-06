# X-phone SystemUI replacement (bacon)

Talkman Lumia 950 RM-1104, MSM8992, Adreno 418, LOS 18.1.
Lunch `lineage_talkman-userdebug`.

This wave **replaces SystemUI look in the ROM image**. Compile-time
`DEVICE_PACKAGE_OVERLAYS` + Java patches. Not more live RROs.

## Forbidden
- `adb push` / `adb install` of `SystemUI.apk` (2026-09-01 zip `#0x0`)
- `adb shell stop`, reboot, Magisk, `ro.hwui.use_vulkan`
- Editing `overlay/` (owned baked DEVICE_PACKAGE_OVERLAYS)
- Editing `overlay-xphone*` (previous RRO wave)
- Editing another slice directory
- Inventing STARLINK as a carrier string
- Overlaying `TextAppearance.Keyguard` (Keyguard inflate crash)
- Copying LiquidGlassKit Metal/Swift
- `mka` / `bacon` (coordinator only)
- Stub HALs, fake battery, CSID test-generator

## Look
Void `#000000`, ink `#E8E8E8`, hairline `#33ffffff`, radii 4–6 dp.
Gesture pill only. Clock `sans-serif-thin`. All-caps tracked labels.
Mockups (do not commit): `assets/xphone-v2-*.png` under the Cursor project.

Glass class in layouts: `com.talkman.glass.TalkmanGlassView`
(alias of `com.talkman.glass.core.TalkmanGlassView`). Keep every stock
`android:id` Java already `findViewById`s.

## Overlay path
Your slice root is a DEVICE_PACKAGE_OVERLAYS directory. Example:

```
systemui-xphone/05-qs/frameworks/base/packages/SystemUI/res/layout/qs_panel.xml
```

Copy the **full** stock XML from `frameworks/base/packages/SystemUI/`, then
edit. Partial layouts fail aapt2.

## Java patches
Write unified diffs under `patches/` in your slice, paths relative to
`frameworks/base/packages/SystemUI/`. Coordinator applies them.

## Done
Leave `DONE.txt` listing every file you wrote.
