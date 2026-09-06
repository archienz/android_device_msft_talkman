# X Phone UI (talkman)

One-page skin brief. Full inventory and mapping: `/home/deck/android/los-18.1/out/xphone-assets.md`. Informal name **X Phone**; tree product stays **talkman**. Not an X / xAI / SpaceX / Apple product.

**Forbidden:** SF Pro, San Francisco, iOS icon packs, official X/Twitter/SpaceX/xAI/Tesla marks, stock iOS or launch-photo walls, Magisk modules that ship any of those.

**Type now (already in LOS 18.1):** Roboto (`sans-serif`), DroidSansMono, Noto fallbacks, Source Sans Pro, ThemePicker **Lato** / **Rubik**. Barlow is OFL in `external/google-fonts/barlow` but not a default UI family.

**Type later** (subset only, `device/msft/talkman/prebuilts/fonts/`, SIL OFL): **Inter** body, **IBM Plex Sans** headlines, **IBM Plex Mono** (or Geist Mono) clock / telemetry. Do not download full variable families.

**Map:** body/caption/button → Inter (now Roboto); titles/toolbars → Plex Sans (now Roboto Medium); status clock → Plex/Geist Mono (now AndroidClock/Roboto). Keep Noto for CJK. New RRO only — do not edit other agents’ overlays.

**Icons:** monochrome white glyphs on `#111114`. User path (no Magisk): Lawnchair + Lawnicons (Apache-2.0) or Arcticons. Optional later: Lucide/Phosphor/Material Symbols vectors, talkman-owned package. Original mark = geometric X in a hairline square — not the X Corp logo.

**Wall:** generated void, 1440×2560, `out/xphone-void-1440x2560.png` (stars + arc + ticks; seed `talkman-xphone-void-20260905`). No stock imagery.

**Chrome:** near-black `#0A0A0A`, off-white `#E8E8E8`, one steel or dim-amber accent. No iOS system blue.

Do not commit from this note. Do not touch modem or kernel.

**Lock (overlay-xphone, SystemUI only):** thin `sans-serif-thin` clock (`widget_big` 76 dp), date skeleton `EEEddMMM` + all-caps tracking, indication `SWIPE UP` above the gestural pill. No camera/phone affordances. No padlock (no FPC). Carrier string stays the real SIM — do not overlay STARLINK. Wallpaper is the void drawable, not this overlay.

