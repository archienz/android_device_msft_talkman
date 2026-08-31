# leftover MATCH 8a6a665: rmnetcli bullhead QMI debug CLI for msm8992
# rmnet_data. Not rild. Dual SIM no.

LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := rmnetcli.c
LOCAL_CFLAGS := -Wall -Werror

LOCAL_C_INCLUDES := $(LOCAL_PATH)/../inc
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../src
LOCAL_C_INCLUDES += $(LOCAL_PATH)

LOCAL_MODULE := rmnetcli
LOCAL_MODULE_TAGS := optional
LOCAL_VENDOR_MODULE := true

LOCAL_SHARED_LIBRARIES := librmnetctl
include $(BUILD_EXECUTABLE)

