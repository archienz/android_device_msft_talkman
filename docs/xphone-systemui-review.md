# X-phone SystemUI review notes (coordinator)

Agents own exclusive dirs. This file is coordinator-only.

## Already baked in `overlay/` (do not rewrite)

`DEVICE_PACKAGE_OVERLAYS` already ships void QS/status/nav/power:

- colors: shade/QS/status/nav handle/global_actions
- dimens: handle 1dp / 96dp, clock 12sp, icons 13dp, tile 11sp, radii 4–6dp, scrims
- styles: StatusBar.Clock, qs_theme, Theme.SystemUI
- drawables: `qs_background_primary.xml`, `qs_navbar_scrim.xml`

New RROs must win on top (priority ≥ 100) or add resources `overlay/` does not have (volume, recents leftovers, Settings, Trebuchet, lock refinements).

## Verified SystemUI names (LOS 18.1)

OK: `qs_customize_background`, `qs_tile_divider`, `qs_subhead`, `qs_tile_text_size`,
`qs_tile_spacing`, `notification_shade_background_color`,
`notification_panel_solid_background`, `notification_divider_color`,
`notification_section_header_label_color`, `scrim_behind_alpha`,
`status_bar_clock_size`, `status_bar_icon_drawing_size`,
`system_bar_background_opaque`, `navigation_handle_radius`,
`navigation_home_handle_width`, `navigation_bar_home_handle_light_color`,
`global_actions_separated_background`, `global_actions_grid_background`,
`shutdown_scrim_behind_alpha`.

MISS as values (they are drawables or absent):

- `qs_background_primary` — drawable, not a color
- `qs_navbar_scrim` — drawable
- `notification_corner_radius` — absent; use `rect_button_radius`

RRO styles: literals only. No `?attr/wallpaperTextColor`, no SystemUI-private parents.

## Glass quality bar (technique, not LiquidGlassKit source)

Must have: IOR refraction, edge-only chromatic dispersion, Fresnel rim, one
specular streak, dual-Kawase on 360×640 cache (3 passes), one panel quad/frame.
Must not: 1440×2560 Gaussian, Vulkan, continuous capture, copy of Metal/Swift.

## Live vs next bacon

- Live on 2026-09-01 zip: `pm install` + `cmd overlay enable` RROs. Demo APK.
- Do not `adb push` SystemUI.apk.
- `libtalkman-glass` + SystemUI inflate hooks wait for next bacon.

## Wire

`talkman-xphone-ui.mk` lists PRODUCT_PACKAGES. Inherit from `device.mk` only
after agents finish and names match.
