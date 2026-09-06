# TalkmanGlassView SystemUI hooks (next bacon)

Notes only. Do **not** edit `frameworks/base`. Do **not** `adb push` `SystemUI.apk`.
Live 2026-09-01 zip stays on product RROs. These insertion points apply when
`libtalkman-glass` + SystemUI are rebuilt together (`mka bacon`).

Class (next image): `com.talkman.glass.TalkmanGlassView` — `GLSurfaceView` /
`TextureView` in package `com.talkman.glass`. SystemUI must compile against
that library or the layout inflater throws `ClassNotFoundException`.

There is **no** view id `qs_background`. The QS plate is view
`@id/quick_settings_background` with drawable `@drawable/qs_background_primary`.

---

## 1. QS panel

Replace the solid QS plate. Keep the same view id so existing Java still binds.

| What | Path / id |
| --- | --- |
| Layout | `frameworks/base/packages/SystemUI/res/layout/qs_panel.xml` |
| Replace this view | `@+id/quick_settings_background` (lines 25–30) |
| Current drawable | `@drawable/qs_background_primary` → `res/drawable/qs_background_primary.xml` |
| Color behind that drawable | `@color/qs_background_dark` (`?android:attr/colorBackgroundFloating`) |
| Root | `com.android.systemui.qs.QSContainerImpl` `@+id/quick_settings_container` |
| QS tiles host | `@+id/quick_settings_panel` (`QSPanel`) |
| Scroll | `@+id/expanded_qs_scroll_view` |
| Header include | `@layout/quick_status_bar_expanded_header` → `@+id/header`, `@+id/quick_qs_panel` |
| Fragment host (shade) | `res/layout/status_bar_expanded.xml` `@+id/qs_frame` |
| Do not replace | `@+id/quick_settings_status_bar_background`, `@+id/quick_settings_gradient_view` (hide them next bacon; they are the black status strip + gradient) |

### Java bind (must keep `@id/quick_settings_background`)

| File | Lines | What |
| --- | --- | --- |
| `…/qs/QSFragment.java` | 114–118 | `inflate(R.layout.qs_panel, …)` |
| `…/qs/QSFragment.java` | 122–140 | `findViewById` for panel / header / footer / `quick_settings_container` |
| `…/qs/QSContainerImpl.java` | 82–92 | `onFinishInflate`: `mBackground = findViewById(R.id.quick_settings_background)` |
| `…/qs/QSContainerImpl.java` | 109–114, 237–240 | `mBackground.setTop` / `setBottom` follow QS expansion |
| `…/qs/QSContainerImpl.java` | 197 | `mBackground.setVisibility` when QS disabled |
| `…/statusbar/phone/StatusBar.java` | 1281–1289 | `findViewById(R.id.qs_frame)` + `ExtensionFragmentListener` → `QSFragment` |

`TalkmanGlassView` must remain a `View` that accepts `setTop` / `setBottom` /
`setVisibility` (plain `View` / `GLSurfaceView` / `TextureView` all do).

Snippet that would land in `qs_panel.xml` on next bacon:
`snippets/qs_panel_quick_settings_background.xml`.

---

## 2. Lock scrim

Lock dim is **not** a layout named `*scrim*.xml`. It is two `ScrimView`s in the
shade window. Glass sits as a **sibling under** `scrim_behind`, not instead of
`ScrimView` (`ScrimController.attachViews` requires `ScrimView`).

| What | Path / id |
| --- | --- |
| Window layout | `frameworks/base/packages/SystemUI/res/layout/super_notification_shade.xml` |
| Inflate | `…/statusbar/SuperStatusBarViewFactory.java` 72–75 `R.layout.super_notification_shade` |
| Wallpaper / media | `@+id/backdrop` (`BackDropView`), children `@+id/backdrop_back`, `@+id/backdrop_front` |
| **Lock scrim (behind)** | `@+id/scrim_behind` (`com.android.systemui.statusbar.ScrimView`) |
| Unlock / front scrim | `@+id/scrim_in_front` (`ScrimView`) |
| Shade include | `@layout/status_bar_expanded` (invisible until expanded) |
| Lock icon (do not glass) | `@+id/lock_icon_container`, `@+id/lock_icon` |
| Not the lock scrim | `@+id/qs_navbar_scrim` in `status_bar_expanded.xml` (96 dp bottom fade) |

Z-order in `super_notification_shade.xml` today:

1. `backdrop`
2. `scrim_behind`  ← insert `TalkmanGlassView` **immediately after `backdrop`, before this**
3. `visualizerview`
4. `status_bar_expanded`
5. `brightness_mirror`
6. `scrim_in_front`
7. `lock_icon_container`

New id (next bacon): `@+id/talkman_glass_lock_scrim`.

### Java attach

| File | Lines | What |
| --- | --- | --- |
| `…/phone/StatusBar.java` | 1553–1563 | `inflateStatusBarWindow()` → factory + `setupExpandedStatusBar()` |
| `…/phone/StatusBar.java` | 1244–1254 | `findViewById(R.id.scrim_behind)` / `scrim_in_front`; `mScrimController.attachViews(…)` |
| `…/phone/StatusBar.java` | 1259–1261 | `R.id.backdrop` + media/wallpaper |
| `…/phone/ScrimController.java` | 111 | `KEYGUARD_SCRIM_ALPHA = 0.2f` |
| `…/phone/ScrimController.java` | 238–255 | `attachViews(ScrimView, ScrimView, ScrimView)` |
| `…/phone/ScrimController.java` | 528–529 | `setScrimBehindDrawable(Drawable)` — **Drawable only**, not a `GLSurfaceView` |
| `…/phone/ScrimState.java` | `KEYGUARD.prepare` | sets `mBehindAlpha = mScrimBehindAlphaKeyguard` (0.2) |

After inflate, `StatusBar.makeStatusBarView` (after line 1254) should
`findViewById(R.id.talkman_glass_lock_scrim)` and drive cache invalidate from
shade drag / wallpaper change. Keep `scrim_behind` for the 0.2 dim (or drop
that alpha next bacon so glass reads). Do not call `setScrimBehindDrawable`
for GLES.

Snippet: `snippets/super_notification_shade_lock_glass.xml`.

---

## 3. Notification stack

The stack **paints** its rounded rect in Java. There is no child view for that
plate. Do **not** add `TalkmanGlassView` as a child of
`NotificationStackScrollLayout` — NSSL treats children as notification rows
(`ExpandableView`).

| What | Path / id |
| --- | --- |
| Layout | `frameworks/base/packages/SystemUI/res/layout/status_bar_expanded.xml` |
| Parent | `@+id/notification_container_parent` (`NotificationsQuickSettingsContainer`) |
| Stack | `@+id/notification_stack_scroller` (`NotificationStackScrollLayout`) |
| Painted plate | `NotificationStackScrollLayout.drawBackground()` / `drawBackgroundRects()` (`mBackgroundPaint`) |
| Gate | `res/values/config.xml` `config_drawNotificationBackground` = `true` |
| Per-row (do not hook) | `status_bar_notification_row.xml` `@id/backgroundNormal`, `@id/backgroundDimmed` |

Insert `TalkmanGlassView` as a **sibling immediately before**
`notification_stack_scroller` (same width / gravity / top margin). New id:
`@+id/talkman_glass_notification_stack`.

`NotificationsQuickSettingsContainer.dispatchDraw` (lines 116–156) only
reorders four known children (`keyguard_user_switcher`, `keyguard_header`,
`notification_stack_scroller`, `qs_frame`). A new sibling is **not** in that
list and draws in XML order — before the stack if it is declared first. That
is the correct z-order.

Next bacon: set `config_drawNotificationBackground` to `false` so NSSL does
not paint a solid round-rect over the glass. Do that in the SystemUI patch,
not in `overlay/` (owned).

### Java bind

| File | Lines | What |
| --- | --- | --- |
| `…/phone/NotificationShadeWindowViewController.java` | 173 | `mView.findViewById(R.id.notification_stack_scroller)` |
| `…/phone/StatusBar.java` | 1122–1123 | same id → `mStackScroller` |
| `…/phone/NotificationPanelViewController.java` | 614–627 | `notification_container_parent`, `notification_stack_scroller`, `qs_frame` |
| `…/phone/NotificationsQuickSettingsContainer.java` | 71–74 | `qs_frame`, `notification_stack_scroller`, `keyguard_header` |
| `…/notification/stack/NotificationStackScrollLayout.java` | 739–743 | `onFinishInflate()` — footer / empty shade only |
| `…/notification/stack/NotificationStackScrollLayout.java` | ~933+ | `drawBackground(Canvas)` — the plate to disable |

After inflate, `NotificationPanelViewController.onFinishInflate` (after line
615) should `findViewById(R.id.talkman_glass_notification_stack)` and match
NSSL bounds / hide-amount if needed.

Snippet: `snippets/status_bar_expanded_stack_glass.xml`.

---

## Inflate chain (all three)

```
StatusBar.inflateStatusBarWindow()
  SuperStatusBarViewFactory.getNotificationShadeWindowView()
    inflate(R.layout.super_notification_shade)     → backdrop, scrim_*, include shade
      include R.layout.status_bar_expanded         → qs_frame, notification_stack_scroller
StatusBar.makeStatusBarView()
  attachViews(scrim_behind, scrim_in_front, …)
  ExtensionFragmentListener → QSFragment
    inflate(R.layout.qs_panel)                     → quick_settings_background
```

---

## Why sideloading `SystemUI.apk` onto the 2026-09-01 zip fails

The telephone runs the **2026-09-01** image. That zip’s
`/system/priv-app/SystemUI/SystemUI.apk`, `framework-res.apk`, and product
RROs (`TalkmanXPhone*`, Lineage SystemUI overlays) were aapt2-compiled
**together**. Resource IDs (`0x7f……` in SystemUI, private `@*android:` in
framework) are integers baked into both `resources.arsc` and `classes.dex`.

A `SystemUI.apk` built from this tree today does not share that ID table.

1. **`@*android:` private IDs** — `qs_panel.xml` uses
   `@*android:dimen/quick_qs_offset_height`. `super_notification_shade.xml`
   uses `@*android:drawable/ic_lock`. Those compile to the **build machine’s**
   `framework-res` private IDs. On the 2026-09-01 zip they are missing or
   different → inflate resolves **0** →
   `Resources.NotFoundException: Resource ID #0x0`.

2. **Nav bar dies first** — `StatusBar.createNavigationBar` →
   `NavigationBarFragment.onCreateView` inflates `R.layout.navigation_bar`
   (`res/layout/navigation_bar.xml`).
   `NavigationBarInflaterView.onFinishInflate` then inflates
   `R.layout.navigation_layout` / `navigation_layout_vertical` and parses
   `R.string.config_navBarLayoutHandle` (gestural) into button drawables.
   That path runs at SystemUI start. One unresolved `@drawable` / `?attr`
   (`TypedArray.getResourceId` → 0) throws `#0x0` and the nav / pill never
   appears. Contract symptom: “nav bar dies: Resource ID #0x0”.

3. **`adb install -r` is not a system replace** — SystemUI is a privileged
   `/system/priv-app` package. An updated APK in `/data/app` still merges
   **product RROs compiled against the zip’s SystemUI public IDs**. Overlays
   then apply to the wrong `0x7f` slots or leave attrs at 0. Same `#0x0`.

4. **`TalkmanGlassView` is not on the 2026-09-01 classpath** — even a
   layout-only sideload that names `com.talkman.glass.TalkmanGlassView`
   `ClassNotFoundException`s. `libtalkman-glass` ships only on next bacon.

5. **Signature / oat** — platform-signed priv-app. A differently signed
   push is rejected; a same-key push without matching `framework-res` +
   wiping oat/vdex still hits (1)–(3).

So: do not replace `SystemUI.apk` on this zip. Live look is RRO. Glass waits
for a full image where SystemUI, framework-res, RROs, and `libtalkman-glass`
are compiled in one `bacon`.
