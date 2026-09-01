#
# Copyright (C) 2015 The Android Open-Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

DEVICE_PATH := device/msft/talkman

BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_USES_BUILD_COPY_HEADERS := true

TARGET_OTA_ASSERT_DEVICE := talkman

# Architecture
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := cortex-a53

# Second architecture
TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv8-a
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := cortex-a53

TARGET_USES_AOSP := true

# Bootloader
TARGET_NO_BOOTLOADER := true
TARGET_NO_RADIOIMAGE := true
TARGET_BOOTLOADER_BOARD_NAME := talkman
TARGET_BOARD_PLATFORM := msm8992

WITH_DEXPREOPT := true
DONT_DEXPREOPT_PREBUILTS := true

TARGET_USE_AOSP_SURFACEFLINGER := true

# kernel
BOARD_KERNEL_BASE        := 0x00000000
BOARD_KERNEL_PAGESIZE    := 4096
BOARD_KERNEL_TAGS_OFFSET := 0x01E00000
BOARD_RAMDISK_OFFSET     := 0x02000000
BOARD_KERNEL_CMDLINE := console=ttyHSL0,115200,n8 androidboot.hardware=talkman boot_cpus=0-5
BOARD_KERNEL_CMDLINE += lpm_levels.sleep_disabled=1 msm_poweroff.download_mode=0
BOARD_KERNEL_CMDLINE += loop.max_part=7 androidboot.boot_devices=soc.0/f9824900.sdhci
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive
# CAF 3.10 g_android. init maps androidboot.usbconfigfs → sys.usb.configfs.
# Force 0 so LOS init.usb.configfs.rc does not take the gadget.
BOARD_KERNEL_CMDLINE += androidboot.usbconfigfs=0
BOARD_KERNEL_CMDLINE += firmware_class.path=/vendor/firmware
# No CONFIG_USB_CONFIGFS. Recovery/vold trees honor this name.
# Leftover bullhead / LOS default TARGET_USES_USB_CONFIGFS := true would
# take the gadget from g_android. Keep false.
TARGET_USES_USB_CONFIGFS := false
BOARD_MKBOOTIMG_ARGS := --ramdisk_offset $(BOARD_RAMDISK_OFFSET) --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
#KERNEL_TOOLCHAIN := $(shell pwd)/prebuilts/arm64-gcc/bin
#KERNEL_TOOLCHAIN_PREFIX := aarch64-elf-
# Audio / NFC / sensor I2C live in android_kernel_mmo_msm8994
# (lineage-18.1-talkman, mmo_defconfig). Talkman DT only.
# Camera (QCamera2 / libmmcamera_interface) and audio HAL pull uapi from
# $(TARGET_OUT_INTERMEDIATES)/KERNEL_OBJ/usr/include on this tree — not
# device kernel-headers/ (bullhead nanohub spi-contexthub leftover).
TARGET_KERNEL_SOURCE := kernel/mmo/msm8994
TARGET_KERNEL_CONFIG := mmo_defconfig
TARGET_KERNEL_CLANG_COMPILE := false
BOARD_KERNEL_IMAGE_NAME := Image.gz-dtb
TARGET_COMPILE_WITH_MSM_KERNEL := true
TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64

# Kernel - prebuilt
#TARGET_FORCE_PREBUILT_KERNEL := true
#ifeq ($(TARGET_FORCE_PREBUILT_KERNEL),true)
#TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilts/kernel
#endif

# APEX
TARGET_FLATTEN_APEX := true

# Audio — TAS2553 on QUAT_MI2S (mixer_paths + audio_platform_info + DT).
# WCD9330 SPK DRV / speaker-protection feedback is not wired. No HAL flag
# named QUAT_MI2S on the 8992 audio-caf HAL; backend is XML, not BoardConfig.
BOARD_USES_ALSA_AUDIO := true
AUDIO_FEATURE_ENABLED_MULTI_VOICE_SESSIONS := true
AUDIO_FEATURE_ENABLED_SPKR_PROTECTION := false
USE_XML_AUDIO_POLICY_CONF := 1

# Binder
TARGET_USES_64_BIT_BINDER := true

# Bluetooth — QCA Rome. Leftover bullhead Broadcom stack is not this SoC.
# Do not set BOARD_HAVE_BLUETOOTH_BCM. MAC: persist /persist/bdaddr.txt or
# chip OTP (NVM tag 2 zeros). QCOM_BT_READ_ADDR_FROM_PROP is the g_use_otpmac
# analog; init.talkman.bt.sh sets ro.boot.btmacaddr from persist or
# 00:00:00:00:00:00. Do not generate a MAC. Do not enable QCOM_BT_USE_BTNV
# (no .bt_nv.bin).
BOARD_HAVE_BLUETOOTH := true
BOARD_HAVE_BLUETOOTH_QCOM := true
# Leave BCM unset. `:= false` is still non-empty, so hardware/broadcom/libbt
# would still build and collide with QCA libbt-vendor.
BOARD_BLUETOOTH_BDROID_BUILDCFG_INCLUDE_DIR := $(DEVICE_PATH)/bluetooth
BOARD_HAS_QCA_BT_ROME := true
WCNSS_FILTER_USES_SIBS := true
QCOM_BT_READ_ADDR_FROM_PROP := true

# Camera — mm-camera v2 32-bit daemon + QCamera2 HAL. Headers: see
# TARGET_COMPILE_WITH_MSM_KERNEL. No 64-bit camera HAL on 8992.
BOARD_QTI_CAMERA_32BIT_ONLY := true
TARGET_USES_MEDIA_EXTENSIONS := true
USE_CAMERA_STUB := false
TARGET_PROCESS_SDK_VERSION_OVERRIDE += \
    /vendor/bin/mm-qcamera-daemon=27

# Charger — qpnp-smbcharger 5 V / ~1.8 A + Qi DCIN. No USB-PD PHY.
BOARD_CHARGER_ENABLE_SUSPEND := true

# Display
BOARD_EGL_CFG := $(DEVICE_PATH)/configs/egl.cfg
MAX_EGL_CACHE_KEY_SIZE := 12*1024
MAX_EGL_CACHE_SIZE := 2048*1024
USE_OPENGL_RENDERER := true
TARGET_USES_ION := true
TARGET_USES_C2D_COMPOSITION := true
TARGET_USES_GRALLOC1_ADAPTER := true
TARGET_USES_HWC2 := true
TARGET_ADDITIONAL_GRALLOC_10_USAGE_BITS := 0x2000U | 0x02000000U
TARGET_DISABLE_POSTRENDER_CLEANUP := true
HAVE_ADRENO_SOURCE:= false
OVERRIDE_RS_DRIVER:= libRSDriver_adreno.so

# Dexpreopt (Enable dex-preoptimization to speed up first boot sequence)
ifeq ($(HOST_OS),linux)
  ifneq ($(TARGET_BUILD_VARIANT),eng)
    ifeq ($(WITH_DEXPREOPT),)
      WITH_DEXPREOPT_BOOT_IMG_AND_SYSTEM_SERVER_ONLY := false
      WITH_DEXPREOPT := true
    endif
  endif
endif

# GPS — MSM8992 IZat / loc HAL (hardware/qcom/gps msm8994). Not nanohub.
BOARD_VENDOR_QCOM_GPS_LOC_API_HARDWARE := $(TARGET_BOARD_PLATFORM)
BOARD_VENDOR_QCOM_LOC_PDK_FEATURE_SET := true
TARGET_NO_RPC := true

# HIDL
PRODUCT_ENFORCE_VINTF_MANIFEST_OVERRIDE := true
DEVICE_MANIFEST_FILE := $(DEVICE_PATH)/manifest.xml
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/vintf/android.hardware.camera.provider@2.4.xml
DEVICE_MATRIX_FILE := $(DEVICE_PATH)/compatibility_matrix.xml
TARGET_FS_CONFIG_GEN += $(DEVICE_PATH)/config.fs

# Partitions
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 33554432
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3221225472
BOARD_SYSTEMIMAGE_JOURNAL_SIZE := 0
# as of 3765008, inode usage was 3011, use 4096 to be safe
BOARD_SYSTEMIMAGE_EXTFS_INODE_COUNT := 4352
BOARD_USERDATAIMAGE_PARTITION_SIZE := 11649679360
BOARD_CACHEIMAGE_PARTITION_SIZE := 100663296
BOARD_CACHEIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_VENDORIMAGE_PARTITION_SIZE := 260046848
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := ext4
BOARD_FLASH_BLOCK_SIZE := 131072
TARGET_COPY_OUT_VENDOR := vendor

BOARD_USES_SECURE_SERVICES := true
BOARD_ROOT_EXTRA_FOLDERS := persist firmware
# CAF libbt-vendor Rome 3.2 opens /bt_firmware/image/{btfw32.tlv,btnv32.bin}.
# Talkman has no BTFM GPT; files are /vendor/firmware (talkman nvm/rampatch).
BOARD_ROOT_EXTRA_FOLDERS += bt_firmware
BOARD_ROOT_EXTRA_SYMLINKS += /vendor/firmware:bt_firmware/image

# Netd
TARGET_OMIT_NETD_TETHER_FTP_HELPER := true

# Peripheral manager
TARGET_PER_MGR_ENABLED := true

# Power — device HIDL 1.0 (power/) writes cpufreq/cpu_boost/msm_performance.
# A57 ceiling 1824000 kHz (CAF table-4 / thermal). Not 1960000. Not qti stub.
TARGET_USES_INTERACTION_BOOST := true
TARGET_USES_NON_LEGACY_POWERHAL := true

# Recovery — default ScreenRecoveryUI. Talkman has no nanohub.
# recovery.fstab (not runtime fstab.talkman): GPT modem VFAT /firmware, vendor ext4, persist, USB-OTG.
BOARD_SUPPRESS_SECURE_ERASE := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab

# Releasetools
TARGET_RELEASETOOLS_EXTENSIONS := $(DEVICE_PATH)

# SELinux
BOARD_SEPOLICY_DIRS += \
    $(DEVICE_PATH)/sepolicy
SELINUX_IGNORE_NEVERALLOWS := true

# Shims
TARGET_LD_SHIM_LIBS := \
    /vendor/bin/ATFWD-daemon|libcutils_shim.so \
    /vendor/bin/cnd|libcutils_shim.so \
    /vendor/lib/libcne.so|libcutils_shim.so \
    /vendor/lib64/libcne.so|libcutils_shim.so


# Telephony
TARGET_USES_ALTERNATIVE_MANUAL_NETWORK_SELECT := true

# Wifi
BOARD_HAS_QCOM_WLAN := true
BOARD_WLAN_DEVICE := qcwcn
WPA_SUPPLICANT_VERSION := VER_0_8_X
BOARD_WPA_SUPPLICANT_DRIVER := NL80211
BOARD_WPA_SUPPLICANT_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
BOARD_HOSTAPD_DRIVER := NL80211
BOARD_HOSTAPD_PRIVATE_LIB := lib_driver_cmd_$(BOARD_WLAN_DEVICE)
WIFI_DRIVER_FW_PATH_STA := "sta"
WIFI_DRIVER_FW_PATH_AP  := "ap"
WIFI_HIDL_UNIFIED_SUPPLICANT_SERVICE_RC_ENTRY := true


# NFC
BOARD_NFC_CHIPSET := pn547
BOARD_NFC_HAL_SUFFIX := msm8992
BOARD_NFC_DEVICE := "/dev/pn547"

# Talkman has no FPC. Leftover bullhead BOARD_HAS_FINGERPRINT_FPC must stay
# unset (do not assign true). Do not ship an FPC HAL.

-include vendor/msft/talkman/BoardConfigVendor.mk
