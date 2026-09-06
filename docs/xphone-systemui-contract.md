# X-phone SystemUI contract (2026-09-05)

Talkman Lumia 950 RM-1104, MSM8992, **Adreno 418**, LOS 18.1 / Android 11.
Lunch `lineage_talkman-userdebug`. Installed zip is **2026-09-01**. Do **not**
`adb push` a new `SystemUI.apk` (nav bar dies: Resource ID #0x0).

## Forbidden
- `ro.hwui.use_vulkan`, Vulkan in HWUI, `CONFIG_MSM_OIS`, stub HALs
- Editing `overlay/` (owned). Edit only your exclusive directory
- `mka`, `adb shell stop`, reboot, GenerateImage, Magisk, SF Pro, iOS icons
- Copying LiquidGlassKit Metal/Swift source (copyright). Re-implement GLES
- Inventing STARLINK as a carrier string

## Look
Void `#000000` + white `#E8E8E8`. Hairline `#33ffffff`. Tight radii 4–6 dp.
Gesture pill only. Type: Roboto / `sans-serif-thin` clock. All-caps tracked
labels. Reference mockups (do not commit):
`/home/deck/.cursor/projects/home-deck-android-los-18-1-device-msft-talkman/assets/xphone-v2-*.png`

## Glass (LiquidGlassKit *technique*, not their code)
Port: refraction (IOR), chromatic dispersion at **bevel only**, Fresnel rim,
one specular streak, frosted blur.
**Budget (A418):** never Gaussian-blur 1440×2560 per frame.
1. Cache wallpaper (or last shade snap) at **360×640** RGBA.
2. Dual-Kawase 3 passes on that cache (GLES 3.1, one FBO ping-pong).
3. Per-frame: **one** panel quad. SDF rounded-rect → bevel normal →
   UV offset + RGB split at edges + Fresnel. Mediump. No branches in inner loop
   if you can `step`/`mix`.
4. Invalidate cache on wallpaper change, or while shade is dragging then
   freeze 250 ms after settle. Do not run continuous capture.
5. HWUI stays GLES. Glass is a `GLSurfaceView` / `TextureView` in
   `com.talkman.glass`.

## Live vs next image
- **Live now:** product RROs like `TalkmanXPhoneLockOverlay` (`pm install` +
  `cmd overlay enable`). Self-contained values (no SystemUI-private attrs).
- **Next bacon:** `libtalkman-glass` + SystemUI hooks under `glass/systemui/`
  as notes/patches. Do not ship those by replacing SystemUI.apk.

## RRO recipe
`BUILD_RRO_PACKAGE`, `LOCAL_PRODUCT_MODULE := true`, `LOCAL_CERTIFICATE := platform`,
`LOCAL_SDK_VERSION := current`, target `com.android.systemui` or the app
package. Literals only in styles (`#ffffffff`, not `?attr/wallpaperTextColor`).
Package names: `com.talkman.overlay.xphone.<slice>`.

## Performance props
Write fragments only in your dir. Do not edit `system.prop` / `device.mk`.
Adreno 418, 60 Hz. Touch boost already 300 MHz GPU / A57 1248. Do not invent
90 Hz.

## Done
Leave `DONE.txt` in your directory listing files you wrote.
