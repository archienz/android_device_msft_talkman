#
# Copyright (C) 2026 The LineageOS Project
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
# Make twin of Android.bp (talkman-glass-demo). Disabled by default so Soong
# and all-makefiles-under do not both register the same module.
# Enable only if building this directory without Soong:
#   TALKMAN_GLASS_DEMO_MAKE=true mka talkman-glass-demo
#

LOCAL_PATH := $(call my-dir)

ifeq ($(TALKMAN_GLASS_DEMO_MAKE),true)
include $(CLEAR_VARS)

LOCAL_PACKAGE_NAME := talkman-glass-demo
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := $(call all-java-files-under, src)
LOCAL_RESOURCE_DIR := $(LOCAL_PATH)/res
LOCAL_MANIFEST_FILE := AndroidManifest.xml
LOCAL_SDK_VERSION := current
LOCAL_MIN_SDK_VERSION := 30
LOCAL_STATIC_JAVA_LIBRARIES := talkman-glass-blur libtalkman-glass
LOCAL_PRODUCT_MODULE := true
LOCAL_DEX_PREOPT := false
LOCAL_PROGUARD_ENABLED := disabled

include $(BUILD_PACKAGE)
endif
