/*
 * Copyright (C) 2016 The Android Open Source Project
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

#define LOG_TAG "GnssHAL_AGnssRilInterface"

#include "AGnssRil.h"
#include "GnssUtils.h"

#include <unistd.h>

namespace android {
namespace hardware {
namespace gnss {
namespace V1_0 {
namespace implementation {

std::vector<std::unique_ptr<ThreadFuncArgs>> AGnssRil::sThreadFuncArgsList;
const AGpsRilInterface* AGnssRil::sAGpsRilIface = nullptr;
sp<IAGnssRilCallback> AGnssRil::sAGnssRilCbIface = nullptr;
bool AGnssRil::sInterfaceExists = false;

AGpsRilCallbacks AGnssRil::sAGnssRilCb = {
    .request_setid = AGnssRil::requestSetId,
    .request_refloc = AGnssRil::requestRefLoc,
    .create_thread_cb = AGnssRil::createThreadCb
};

AGnssRil::AGnssRil(const AGpsRilInterface* aGpsRilIface)
        : mAGnssRilIface(aGpsRilIface), mWlanWatchRun(false), mWlanWasUp(false) {
    /* Error out if an instance of the interface already exists. */
    LOG_ALWAYS_FATAL_IF(sInterfaceExists);
    sInterfaceExists = true;
    sAGpsRilIface = aGpsRilIface;
}

AGnssRil::~AGnssRil() {
    if (mWlanWatchRun.exchange(false)) {
        pthread_join(mWlanThread, nullptr);
    }
    sThreadFuncArgsList.clear();
    sAGpsRilIface = nullptr;
    sInterfaceExists = false;
}

void* AGnssRil::wlanWatchFn(void* arg) {
    reinterpret_cast<AGnssRil*>(arg)->wlanWatchLoop();
    return nullptr;
}

void AGnssRil::startWlanWatch() {
    if (mWlanWatchRun.exchange(true)) {
        return;
    }
    int err = pthread_create(&mWlanThread, nullptr, wlanWatchFn, this);
    if (err != 0) {
        ALOGE("%s: pthread_create failed %d", __func__, err);
        mWlanWatchRun.store(false);
        return;
    }
    pthread_setname_np(mWlanThread, "AgpsWlanWatch");
}

void AGnssRil::injectWlanNetworkState(bool up) {
    if (mAGnssRilIface == nullptr) {
        return;
    }
    std::lock_guard<std::mutex> lock(mLock);
    mAGnssRilIface->update_network_state(up ? 1 : 0, AGPS_RIL_NETWORK_TYPE_WIFI, 0, nullptr);
    mAGnssRilIface->update_network_availability(up ? 1 : 0, "wlan0");
}

void AGnssRil::wlanWatchLoop() {
    bool up = talkmanWlanIsUp();
    mWlanWasUp.store(up);
    ALOGI("%s: initial wlan0 %s", __func__, up ? "up" : "down");
    injectWlanNetworkState(up);
    while (mWlanWatchRun.load()) {
        usleep(1000 * 1000);
        if (!mWlanWatchRun.load()) {
            break;
        }
        up = talkmanWlanIsUp();
        bool was = mWlanWasUp.exchange(up);
        if (up != was) {
            ALOGI("%s: wlan0 %s - inject AGPS network (no RIL)", __func__,
                  up ? "up" : "down");
            injectWlanNetworkState(up);
        }
    }
}

void AGnssRil::requestSetId(uint32_t flags) {
    ALOGI("%s: no RIL subscriber id flags=0x%x", __func__, flags);
    if (sAGpsRilIface != nullptr) {
        sAGpsRilIface->set_set_id(AGPS_SETID_TYPE_NONE, "");
    }
    // Do not request IMSI/MSISDN from the framework.
}

void AGnssRil::requestRefLoc(uint32_t /*flags*/) {
    // No cell ID without RIL. Do not invent a tower.
    ALOGI("%s: no RIL cell refloc", __func__);
}

pthread_t AGnssRil::createThreadCb(const char* name, void (*start)(void*), void* arg) {
    return createPthread(name, start, arg, &sThreadFuncArgsList);
}

// Methods from ::android::hardware::gnss::V1_0::IAGnssRil follow.
Return<void> AGnssRil::setCallback(const sp<IAGnssRilCallback>& callback)  {
    if (mAGnssRilIface == nullptr) {
        ALOGE("%s: AGnssRil interface is unavailable", __func__);
        return Void();
    }

    sAGnssRilCbIface = callback;

    mAGnssRilIface->init(&sAGnssRilCb);
    mAGnssRilIface->set_set_id(AGPS_SETID_TYPE_NONE, "");
    startWlanWatch();
    return Void();
}

Return<void> AGnssRil::setRefLocation(const IAGnssRil::AGnssRefLocation& aGnssRefLocation)  {
    if (mAGnssRilIface == nullptr) {
        ALOGE("%s: AGnssRil interface is unavailable", __func__);
        return Void();
    }

    AGpsRefLocation aGnssRefloc;
    aGnssRefloc.type = static_cast<uint16_t>(aGnssRefLocation.type);

    auto& cellID = aGnssRefLocation.cellID;
    aGnssRefloc.u.cellID = {
        .type = static_cast<uint16_t>(cellID.type),
        .mcc = cellID.mcc,
        .mnc = cellID.mnc,
        .lac = cellID.lac,
        .cid = cellID.cid,
        .tac = cellID.tac,
        .pcid = cellID.pcid
    };

    mAGnssRilIface->set_ref_location(&aGnssRefloc, sizeof(aGnssRefloc));
    return Void();
}

Return<bool> AGnssRil::setSetId(IAGnssRil::SetIDType type, const hidl_string& setid)  {
    if (mAGnssRilIface == nullptr) {
        ALOGE("%s: AGnssRil interface is unavailable", __func__);
        return false;
    }

    (void)setid;
    if (type != IAGnssRil::SetIDType::NONE) {
        ALOGI("%s: drop IMSI/MSISDN set-id type=%u", __func__,
              static_cast<unsigned>(type));
    }
    std::lock_guard<std::mutex> lock(mLock);
    mAGnssRilIface->set_set_id(AGPS_SETID_TYPE_NONE, "");
    return true;
}

Return<bool> AGnssRil::updateNetworkState(bool connected,
                                          IAGnssRil::NetworkType type,
                                          bool roaming) {
    if (mAGnssRilIface == nullptr) {
        ALOGE("%s: AGnssRil interface is unavailable", __func__);
        return false;
    }

    mAGnssRilIface->update_network_state(connected,
                                         static_cast<int>(type),
                                         roaming,
                                         nullptr /* extra_info */);
    if (type == IAGnssRil::NetworkType::WIFI) {
        mWlanWasUp.store(connected);
    }
    return true;
}

Return<bool> AGnssRil::updateNetworkAvailability(bool available, const hidl_string& apn)  {
    if (mAGnssRilIface == nullptr) {
        ALOGE("%s: AGnssRil interface is unavailable", __func__);
        return false;
    }

    mAGnssRilIface->update_network_availability(available, apn.c_str());
    return true;
}

}  // namespace implementation
}  // namespace V1_0
}  // namespace gnss
}  // namespace hardware
}  // namespace android
