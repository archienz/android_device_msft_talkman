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

#define LOG_TAG "android.hardware.camera.provider@2.4-service.talkman-smiapp"

#include <android/hardware/camera/provider/2.4/ICameraProvider.h>
#include <hidl/HidlTransportSupport.h>
#include <log/log.h>

#include "SmiappCameraProvider.h"

using android::OK;
using android::sp;
using android::hardware::configureRpcThreadpool;
using android::hardware::joinRpcThreadpool;
using android::hardware::camera::provider::V2_4::ICameraProvider;
using android::hardware::camera::provider::V2_4::implementation::SmiappCameraProvider;

// Distinct from leftover QCamera2 passthrough instance "legacy/0".
static constexpr const char* kInstance = "smiapp/0";

int main() {
    ALOGI("talkman SMIApp camera.provider stub starting (disabled path, no sensors)");

    configureRpcThreadpool(1, true /* callerWillJoin */);

    sp<ICameraProvider> provider = new SmiappCameraProvider();
    const android::status_t status = provider->registerAsService(kInstance);
    if (status != OK) {
        ALOGE("Could not register ICameraProvider/%s: %d", kInstance, status);
        return 1;
    }

    joinRpcThreadpool();
    ALOGE("talkman SMIApp camera.provider stub exited");
    return 1;
}
