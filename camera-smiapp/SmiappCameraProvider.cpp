/*
 * Copyright (C) 2026 The LineageOS Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#define LOG_TAG "SmiappCameraProvider"

#include "SmiappCameraProvider.h"

#include <log/log.h>

namespace android {
namespace hardware {
namespace camera {
namespace provider {
namespace V2_4 {
namespace implementation {

Return<Status> SmiappCameraProvider::setCallback(
        const sp<ICameraProviderCallback>& callback) {
    if (callback == nullptr) {
        return Status::ILLEGAL_ARGUMENT;
    }
    // No sensors to announce. Firmware is not in this tree.
    return Status::OK;
}

Return<void> SmiappCameraProvider::getVendorTags(getVendorTags_cb _hidl_cb) {
    hidl_vec<VendorTagSection> empty;
    _hidl_cb(Status::OK, empty);
    return Void();
}

Return<void> SmiappCameraProvider::getCameraIdList(getCameraIdList_cb _hidl_cb) {
    // Empty list is correct until Icaros / SMIApp firmware exists.
    hidl_vec<hidl_string> empty;
    ALOGI("talkman SMIApp stub: no camera ids (Icaros firmware not present)");
    _hidl_cb(Status::OK, empty);
    return Void();
}

Return<void> SmiappCameraProvider::isSetTorchModeSupported(
        isSetTorchModeSupported_cb _hidl_cb) {
    // Torch is Harmony gpio-leds led::flash_torch + lights HAL.
    // Do not implement a QS torch HIDL from this stub.
    _hidl_cb(Status::OK, false);
    return Void();
}

Return<void> SmiappCameraProvider::getCameraDeviceInterface_V1_x(
        const hidl_string& cameraDeviceName,
        getCameraDeviceInterface_V1_x_cb _hidl_cb) {
    ALOGW("talkman SMIApp stub: no V1 device for '%s'", cameraDeviceName.c_str());
    _hidl_cb(Status::ILLEGAL_ARGUMENT, nullptr);
    return Void();
}

Return<void> SmiappCameraProvider::getCameraDeviceInterface_V3_x(
        const hidl_string& cameraDeviceName,
        getCameraDeviceInterface_V3_x_cb _hidl_cb) {
    ALOGW("talkman SMIApp stub: no V3 device for '%s'", cameraDeviceName.c_str());
    _hidl_cb(Status::ILLEGAL_ARGUMENT, nullptr);
    return Void();
}

}  // namespace implementation
}  // namespace V2_4
}  // namespace provider
}  // namespace camera
}  // namespace hardware
}  // namespace android
