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

#ifndef DEVICE_MSFT_TALKMAN_CAMERA_SMIAPP_SMIAPPCAMERAPROVIDER_H
#define DEVICE_MSFT_TALKMAN_CAMERA_SMIAPP_SMIAPPCAMERAPROVIDER_H

#include <android/hardware/camera/provider/2.4/ICameraProvider.h>
#include <hidl/MQDescriptor.h>
#include <hidl/Status.h>

namespace android {
namespace hardware {
namespace camera {
namespace provider {
namespace V2_4 {
namespace implementation {

using ::android::sp;
using ::android::hardware::hidl_string;
using ::android::hardware::hidl_vec;
using ::android::hardware::Return;
using ::android::hardware::Void;
using ::android::hardware::camera::common::V1_0::Status;
using ::android::hardware::camera::common::V1_0::VendorTagSection;
using ::android::hardware::camera::provider::V2_4::ICameraProvider;
using ::android::hardware::camera::provider::V2_4::ICameraProviderCallback;

/**
 * Compile-only talkman SMIApp camera.provider@2.4 stub.
 *
 * No Icaros firmware, no CSI programming, no sensor list.
 * Not the live device camera.provider (leftover QCamera2 stays legacy/0).
 */
struct SmiappCameraProvider : public ICameraProvider {
    Return<Status> setCallback(const sp<ICameraProviderCallback>& callback) override;
    Return<void> getVendorTags(getVendorTags_cb _hidl_cb) override;
    Return<void> getCameraIdList(getCameraIdList_cb _hidl_cb) override;
    Return<void> isSetTorchModeSupported(isSetTorchModeSupported_cb _hidl_cb) override;
    Return<void> getCameraDeviceInterface_V1_x(
            const hidl_string& cameraDeviceName,
            getCameraDeviceInterface_V1_x_cb _hidl_cb) override;
    Return<void> getCameraDeviceInterface_V3_x(
            const hidl_string& cameraDeviceName,
            getCameraDeviceInterface_V3_x_cb _hidl_cb) override;
};

}  // namespace implementation
}  // namespace V2_4
}  // namespace provider
}  // namespace camera
}  // namespace hardware
}  // namespace android

#endif  // DEVICE_MSFT_TALKMAN_CAMERA_SMIAPP_SMIAPPCAMERAPROVIDER_H
