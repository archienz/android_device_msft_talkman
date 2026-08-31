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

#include "GnssUtils.h"

#include <fcntl.h>
#include <unistd.h>

namespace android {
namespace hardware {
namespace gnss {
namespace V1_0 {
namespace implementation {

using android::hardware::gnss::V1_0::GnssLocation;

GnssLocation convertToGnssLocation(GpsLocation* location) {
    GnssLocation gnssLocation = {};
    if (location != nullptr) {
        gnssLocation = {
            // Bit operation AND with 1f below is needed to clear vertical accuracy,
            // speed accuracy and bearing accuracy flags as some vendors are found
            // to be setting these bits in pre-Android-O devices
            .gnssLocationFlags = static_cast<uint16_t>(location->flags & 0x1f),
            .latitudeDegrees = location->latitude,
            .longitudeDegrees = location->longitude,
            .altitudeMeters = location->altitude,
            .speedMetersPerSec = location->speed,
            .bearingDegrees = location->bearing,
            .horizontalAccuracyMeters = location->accuracy,
            // Older chipsets do not provide the following 3 fields, hence the flags
            // HAS_VERTICAL_ACCURACY, HAS_SPEED_ACCURACY and HAS_BEARING_ACCURACY are
            // not set and the field are set to zeros.
            .verticalAccuracyMeters = 0,
            .speedAccuracyMetersPerSecond = 0,
            .bearingAccuracyDegrees = 0,
            .timestamp = location->timestamp
        };
    }

    return gnssLocation;
}

GnssLocation convertToGnssLocation(FlpLocation* flpLocation) {
    GnssLocation gnssLocation = {};
    if (flpLocation != nullptr) {
        gnssLocation = {.gnssLocationFlags = 0,  // clear here and set below
                        .latitudeDegrees = flpLocation->latitude,
                        .longitudeDegrees = flpLocation->longitude,
                        .altitudeMeters = flpLocation->altitude,
                        .speedMetersPerSec = flpLocation->speed,
                        .bearingDegrees = flpLocation->bearing,
                        .horizontalAccuracyMeters = flpLocation->accuracy,
                        .verticalAccuracyMeters = 0,
                        .speedAccuracyMetersPerSecond = 0,
                        .bearingAccuracyDegrees = 0,
                        .timestamp = flpLocation->timestamp};
        // FlpLocation flags different from GnssLocation flags
        if (flpLocation->flags & FLP_LOCATION_HAS_LAT_LONG) {
            gnssLocation.gnssLocationFlags |= GPS_LOCATION_HAS_LAT_LONG;
        }
        if (flpLocation->flags & FLP_LOCATION_HAS_ALTITUDE) {
            gnssLocation.gnssLocationFlags |= GPS_LOCATION_HAS_ALTITUDE;
        }
        if (flpLocation->flags & FLP_LOCATION_HAS_SPEED) {
            gnssLocation.gnssLocationFlags |= GPS_LOCATION_HAS_SPEED;
        }
        if (flpLocation->flags & FLP_LOCATION_HAS_BEARING) {
            gnssLocation.gnssLocationFlags |= GPS_LOCATION_HAS_BEARING;
        }
        if (flpLocation->flags & FLP_LOCATION_HAS_ACCURACY) {
            gnssLocation.gnssLocationFlags |= GPS_LOCATION_HAS_HORIZONTAL_ACCURACY;
        }
    }

    return gnssLocation;
}

bool talkmanWlanIsUp() {
    int fd = open("/sys/class/net/wlan0/carrier", O_RDONLY | O_CLOEXEC);
    if (fd >= 0) {
        char buf[8] = {};
        ssize_t n = read(fd, buf, sizeof(buf) - 1);
        close(fd);
        if (n > 0 && buf[0] == '1') {
            return true;
        }
    }
    fd = open("/sys/class/net/wlan0/operstate", O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
        return false;
    }
    char buf[16] = {};
    ssize_t n = read(fd, buf, sizeof(buf) - 1);
    close(fd);
    return n >= 2 && buf[0] == 'u' && buf[1] == 'p';
}

}  // namespace implementation
}  // namespace V1_0
}  // namespace gnss
}  // namespace hardware
}  // namespace android
