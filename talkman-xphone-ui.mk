# X-phone UI product packages (RROs + glass demo/lib).
# DONE: this fragment only. device.mk should inherit it — do not edit device.mk here:
#   $(call inherit-product, device/msft/talkman/talkman-xphone-ui.mk)
#
# Live 2026-09-01 zip: product RROs only. Do not adb push SystemUI.apk.
# Next bacon: compile-time overlays under systemui-xphone/ replace SystemUI
# resources. Later overlay dirs win on the same name.

PRODUCT_SOONG_NAMESPACES += device/msft/talkman

DEVICE_PACKAGE_OVERLAYS += \
    device/msft/talkman/systemui-xphone/01-theme \
    device/msft/talkman/systemui-xphone/02-lock \
    device/msft/talkman/systemui-xphone/03-shade \
    device/msft/talkman/systemui-xphone/04-notif \
    device/msft/talkman/systemui-xphone/05-qs \
    device/msft/talkman/systemui-xphone/06-status \
    device/msft/talkman/systemui-xphone/07-nav \
    device/msft/talkman/systemui-xphone/08-volume \
    device/msft/talkman/systemui-xphone/09-power \
    device/msft/talkman/systemui-xphone/10-recents \
    device/msft/talkman/systemui-xphone/11-scrim \
    device/msft/talkman/systemui-xphone/12-shade-window \
    device/msft/talkman/systemui-xphone/13-fw-notif \
    device/msft/talkman/systemui-xphone/16-keyguard

PRODUCT_PACKAGES += \
    TalkmanXPhoneLockOverlay \
    TalkmanXPhoneStatusOverlay \
    TalkmanXPhoneNavOverlay \
    TalkmanXPhoneShadeOverlay \
    TalkmanXPhoneQsOverlay \
    TalkmanXPhoneVolumeOverlay \
    TalkmanXPhonePowerOverlay \
    TalkmanXPhoneRecentsOverlay \
    TalkmanXPhoneSettingsOverlay \
    TalkmanXPhoneLauncherOverlay \
    TalkmanXPhoneNotifOverlay \
    talkman-glass-demo \
    TalkmanClock \
    TalkmanDialer \
    TalkmanMessages \
    TalkmanWidgets

# libtalkman-glass is a static java_library (installable: false).
# talkman-glass-demo pulls it via static_libs. Do not PRODUCT_PACKAGES it.

# From glass/perf/talkman-glass-perf.prop. Adreno 418: no SF window blur,
# HWUI stays Skia GLES. Do not assign ro.hwui.use_vulkan.
PRODUCT_PROPERTY_OVERRIDES += \
    persist.sys.sf.disable_blurs=1 \
    ro.surface_flinger.supports_background_blur=0 \
    debug.hwui.renderer=skiagl
