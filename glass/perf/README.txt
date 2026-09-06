talkman glass/perf — Adreno 418 / 60 Hz property fragment
=========================================================

This directory is a fragment. It is not merged into the running image.
Do not edit system.prop, vendor.prop, or device.mk from here.

File: talkman-glass-perf.prop
Target: Lumia 950 RM-1104, MSM8992, Adreno 418, 1440×2560 @ 60 Hz TE.
Tree: LOS 18.1 / Android 11 (AOSP R SurfaceFlinger + HWUI).

Assigned keys (3)
-----------------

persist.sys.sf.disable_blurs=1
  AOSP R debug / user preference. Read in
  SurfaceFlinger::readPersistentProperties() and in SystemUI
  BlurUtils (Kotlin + shared BlurUtils.java).
  Effect: SF skips layer_state_t::eBackgroundBlurRadiusChanged
  (requires both !mDisableBlurs and mSupportsBlur). SystemUI
  supportsBlursOnWindows() becomes false, so shade / dialogs do
  not request window blur.
  Why A418-safe: no shader change, no HWC path change, no vsync
  change. The expensive work (RenderEngine blur of the 1440×2560
  framebuffer) never starts. Glass frost is a separate GLES
  SurfaceView in com.talkman.glass (360×640 Dual-Kawase), not
  this SF path.

ro.surface_flinger.supports_background_blur=0
  AOSP R capability. SF ctor, default already "0". SystemUI
  BlurUtils reads the same name (default false).
  Effect: mSupportsBlur stays false; RenderEngine is built
  without the background-blur program. AOSP default is already
  off; this pins it so a later inherit cannot turn SF blur on.
  Why A418-safe: matches stock AOSP default. Enabling it (1)
  would allocate a full-res blur that the glass contract forbids
  (never Gaussian-blur 1440×2560 per frame). GLES 3.1 on A418
  would pass the GLESRenderEngine "needs GLES 3.0" fatal, so
  the fatal is not the reason — fill-rate is.

debug.hwui.renderer=skiagl
  AOSP HWUI debug flag (Properties.h PROPERTY_RENDERER).
  Effect: Skia OpenGL backend. If this key is absent, HWUI
  already chooses skiagl whenever ro.hwui.use_vulkan is unset.
  Pinning it keeps GLES if someone later assigns use_vulkan.
  Why A418-safe: this is the path the telephone already runs
  (Settings fling / HWC device composition). skiavk is not
  viable: Android 11 Skia Vulkan requires Vulkan 1.1;
  vulkan.msm8992.so is 1.0 and has no AHardwareBuffer import.

Must stay unset
---------------

ro.hwui.use_vulkan
  Do not assign true or false. HWUI Properties.cpp:
  GetBoolProperty("ro.hwui.use_vulkan", false) then defaults
  debug.hwui.renderer to skiavk vs skiagl. Contract, vulkan/HWUI.txt,
  system.prop comment, and vendor.prop comment all require this
  name to remain unassigned. True = black UI / Skia Vulkan fatal
  on this ICD. False is redundant and would still "set" the key.

ro.sf.blurs_are_expensive
  Not a disable. When 1, Output.cpp only sets
  setExpensiveRenderingExpected() if a layer is already blurring.
  Does not skip the blur shader. Leave unset.

Existing floors (do not copy into this fragment)
------------------------------------------------

GPU wake/floor 300 MHz and A57 1248 MHz / 1.5 s live in
powerhint.xml + init.talkman.power.sh (measured
out/qa-gpu-touch-20260902-1749/).

SF phase offsets live in system.prop:
  debug.sf.use_phase_offsets_as_durations=1
  debug.sf.*.sf.duration=5500000
  debug.sf.*.app.duration=15500000

device.mk already has:
  debug.sf.disable_backpressure=1
  debug.sf.enable_gl_backpressure=1
  debug.sf.latch_unsignaled=1

system.prop already has ro.hwui.* cache sizes, ro.opengles.version,
persist.hwc.mdpcomp.enable, ro.hardware.vulkan=msm8992 (ICD name
only). Comment them in the .prop; do not repeat the assignments.

Do not add
----------

90/120 Hz, ro.min_freq_*, kgsl min_pwrlevel, debug.sf.*duration,
ro.hwui.use_vulkan, CONFIG_MSM_OIS, stub HALs, overlay/ edits.
