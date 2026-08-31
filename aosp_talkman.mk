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

# AOSP product makefile. Daily lunch is lineage_talkman-userdebug.
# Cellular/RIL is P2 — do not treat radio as P0 here.

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)

$(call inherit-product, device/msft/talkman/device.mk)
$(call inherit-product, vendor/msft/talkman/talkman-vendor.mk)

PRODUCT_NAME := aosp_talkman
PRODUCT_DEVICE := talkman
PRODUCT_BRAND := Microsoft
PRODUCT_MODEL := Lumia 950
PRODUCT_MANUFACTURER := Microsoft
PRODUCT_RESTRICT_VENDOR_FILES := false

PRODUCT_BUILD_PROP_OVERRIDES += \
    PRODUCT_NAME=talkman \
    PRIVATE_BUILD_DESC="talkman-user 11 RQ3A.211001.001 1 release-keys"

BUILD_FINGERPRINT := Microsoft/talkman/talkman:11/RQ3A.211001.001/1:user/release-keys
