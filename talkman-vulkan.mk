# Talkman Adreno 418 Vulkan ICD extra install paths.
#
# talkman-vendor.mk already copies:
#   vendor/msft/talkman/proprietary/vendor/lib/hw/vulkan.msm8992.so
#     -> $(TARGET_COPY_OUT_VENDOR)/lib/hw/vulkan.msm8992.so
#   vendor/msft/talkman/proprietary/vendor/lib64/hw/vulkan.msm8992.so
#     -> $(TARGET_COPY_OUT_VENDOR)/lib64/hw/vulkan.msm8992.so
# SPHAL / libvulkan may not search /vendor/lib{,64}/hw. Same sources,
# different dests (no hw/), so this is not a duplicate PRODUCT_COPY_FILES dest.
#
# Feature XML stays android.hardware.vulkan.version-1_0_3 (device.mk).
# Do not advertise 1.1 or 1.4. Do not set ro.hwui.use_vulkan.

PRODUCT_PACKAGES += \
    talkman-vk-probe \
    talkman-vk-probe32 \
    talkman-vk-tri \
    talkman-vk-clear \
    talkman-vk-caps \
    talkman-vk-fence \
    talkman-vk-mem \
    talkman-vk-cap \
    talkman-vk-present \
    talkman-vk-sfwin

PRODUCT_COPY_FILES += \
    vendor/msft/talkman/proprietary/vendor/lib/hw/vulkan.msm8992.so:$(TARGET_COPY_OUT_VENDOR)/lib/vulkan.msm8992.so \
    vendor/msft/talkman/proprietary/vendor/lib64/hw/vulkan.msm8992.so:$(TARGET_COPY_OUT_VENDOR)/lib64/vulkan.msm8992.so
