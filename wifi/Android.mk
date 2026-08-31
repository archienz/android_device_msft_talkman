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

# qcacld-2.0 request_firmware("wlan/qca_cld/wlan_mac.bin"). Point that
# at the standard Android persist file. Do not ship a MAC in the tree.
# Module is talkman_wlan_mac (not bullhead_wlan_mac).
#
# BUILD_PHONY_PACKAGE is uninstallable, so LOCAL_POST_INSTALL_CMD never
# runs. Install persist symlinks as real make targets (same pattern as
# IMS_SYMLINKS in device Android.mk).
# Source of the persist file: installer provision.sh copies factory
# bytes from DPP/QCOM/WLAN.PROVISION. Empty persist -> g_use_otpmac=1.

include $(CLEAR_VARS)
LOCAL_MODULE := talkman_wlan_mac
include $(BUILD_PHONY_PACKAGE)

WLAN_MAC_SYMLINKS := \
    $(TARGET_OUT_ETC)/firmware/wlan/qca_cld/wlan_mac.bin \
    $(TARGET_OUT_VENDOR)/firmware/wlan/qca_cld/wlan_mac.bin
$(WLAN_MAC_SYMLINKS):
	@echo "wlan_mac.bin persist symlink: $@"
	@mkdir -p $(dir $@)
	@rm -rf $@
	$(hide) ln -sf /persist/wlan_mac.bin $@
ALL_DEFAULT_INSTALLED_MODULES += $(WLAN_MAC_SYMLINKS)
WLAN_MAC_SYMLINKS :=
