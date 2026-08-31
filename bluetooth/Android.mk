#
# Copyright 2015 The Android Open Source Project
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

LOCAL_PATH := $(call my-dir)

# Persist BD_ADDR: chmod /persist/bdaddr.txt or leave QCA OTP.
# Leftover bullhead Broadcom did not apply. Do not ship or generate a MAC.
include $(CLEAR_VARS)
LOCAL_MODULE := init.talkman.bt.sh
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_SRC_FILES := init.talkman.bt.sh
LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR_EXECUTABLES)
include $(BUILD_PREBUILT)

# QCA6174 UART + firmware paths. No BD_ADDR in the conf.
include $(CLEAR_VARS)
LOCAL_MODULE := bt_vendor.conf
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := ETC
LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR)/etc/bluetooth
LOCAL_SRC_FILES := bt_vendor.conf
include $(BUILD_PREBUILT)
ALL_DEFAULT_INSTALLED_MODULES += $(LOCAL_INSTALLED_MODULE)
