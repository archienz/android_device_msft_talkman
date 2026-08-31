LOCAL_PATH := $(call my-dir)

# mm-qcamera-daemon SensorName mot_imx230. No CameraId 1. No slave-id.
include $(CLEAR_VARS)
LOCAL_MODULE := msm8992_camera.xml
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := msm8992_camera.xml
LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR_ETC)/camera
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := mot_imx230_chromatix.xml
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := mot_imx230_chromatix.xml
LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR_ETC)/camera
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := msm8992_camera.xml.system
LOCAL_MODULE_STEM := msm8992_camera.xml
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := msm8992_camera.xml
LOCAL_MODULE_PATH := $(TARGET_OUT_ETC)/camera
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_MODULE := mot_imx230_chromatix.xml.system
LOCAL_MODULE_STEM := mot_imx230_chromatix.xml
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := mot_imx230_chromatix.xml
LOCAL_MODULE_PATH := $(TARGET_OUT_ETC)/camera
include $(BUILD_PREBUILT)

# TODO:  Find a better way to separate build configs for ADP vs non-ADP devices
ifneq ($(TARGET_BOARD_AUTO),true)
  ifneq ($(filter msm8992 msm8994,$(TARGET_BOARD_PLATFORM)),)
    ifneq ($(strip $(USE_CAMERA_STUB)),true)
      ifneq ($(BUILD_TINY_ANDROID),true)
        include $(call all-subdir-makefiles)
      endif
    endif
  endif
endif
