/*
 * Copyright (C) 2019 The Android Open Source Project
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

/*
 * Talkman splits the battery across two power_supply nodes:
 *
 *   qpnp-fg.c        chip->bms_psy.name = "bms"
 *                    chip->bms_psy.type = POWER_SUPPLY_TYPE_BMS
 *   qpnp-smbcharger  chip->batt_psy.name = "battery"
 *                    chip->batt_psy.type = POWER_SUPPLY_TYPE_BATTERY
 *
 * BatteryMonitor::readPowerSupplyType() has no "BMS" entry, so "bms" maps to
 * ANDROID_POWER_SUPPLY_TYPE_UNKNOWN and is skipped. Every path is autodetected
 * under "battery" instead. smbchg_battery_properties[] does not contain
 * POWER_SUPPLY_PROP_CHARGE_FULL, CHARGE_FULL_DESIGN or CYCLE_COUNT -- only
 * fg_power_props[] does -- so batteryFullChargePath, batteryCycleCountPath and
 * batteryFullChargeDesignCapacityUahPath stay empty and healthd logs
 * "<name> not found". The HIDL fields then report 0.
 *
 * BatteryMonitor::init() only autodetects a path that is still empty, so
 * pinning the three fuel-gauge paths here is enough; capacity, status, health,
 * voltage, current, temp and charge_counter are left to autodetect on
 * "battery", which is where smbcharger proxies them from the gauge.
 */

#include <errno.h>

#include <memory>
#include <optional>
#include <string>
#include <string_view>

#include <android-base/file.h>
#include <android-base/parseint.h>
#include <android-base/strings.h>
#include <health/utils.h>
#include <health2impl/Health.h>
#include <utils/String8.h>

using ::android::hardware::health::InitHealthdConfig;
using ::android::hardware::health::V2_1::IHealth;
using ::android::hardware::health::V2_1::implementation::Health;

using namespace std::literals;

namespace {

constexpr char kFgChargeFull[] = "/sys/class/power_supply/bms/charge_full";
constexpr char kFgChargeFullDesign[] = "/sys/class/power_supply/bms/charge_full_design";
constexpr char kFgCycleCount[] = "/sys/class/power_supply/bms/cycle_count";
constexpr char kFgChargeNow[] = "/sys/class/power_supply/bms/charge_now";
constexpr char kFgVoltageNow[] = "/sys/class/power_supply/bms/voltage_now";

std::optional<int64_t> ReadInt64(const char* path) {
    std::string buf;
    if (!::android::base::ReadFileToString(path, &buf)) {
        return std::nullopt;
    }
    int64_t value = 0;
    if (!::android::base::ParseInt(::android::base::Trim(buf), &value)) {
        return std::nullopt;
    }
    return value;
}

/*
 * healthd_config::energyCounter reports remaining energy in nWh.
 *
 * qpnp-fg returns charge_now as learning_data.cc_uah (uAh) and voltage_now from
 * FG_DATA_VOLTAGE (uV). uAh * uV is 1e-12 Wh, and nWh is 1e-9 Wh, so the nWh
 * value is that product divided by 1000. 3000 mAh at 4.4 V is ~1.3e10 nWh,
 * well inside int64_t.
 *
 * cc_uah is coulomb-counter learning state: it reads 0 until the gauge has
 * completed a charge cycle against the microsoft_bvt5e_3000mah profile. Report
 * an error in that case instead of 0 nWh so callers treat it as unavailable
 * rather than as an empty battery.
 */
int TalkmanEnergyCounter(int64_t* energy) {
    std::optional<int64_t> charge_uah = ReadInt64(kFgChargeNow);
    std::optional<int64_t> voltage_uv = ReadInt64(kFgVoltageNow);

    if (!charge_uah.has_value() || !voltage_uv.has_value()) {
        return -ENOENT;
    }
    if (*charge_uah <= 0 || *voltage_uv <= 0) {
        return -EAGAIN;
    }

    *energy = (*charge_uah * *voltage_uv) / 1000;
    return 0;
}

}  // namespace

/*
 * batteryCapacityLevel and batteryChargeTimeToFullNowSeconds are deliberately
 * left at BatteryMonitor's UNSUPPORTED default.
 *
 * CAF 3.10 qpnp-fg exports neither POWER_SUPPLY_PROP_CAPACITY_LEVEL nor a
 * time-to-full property, so there is no sysfs source for either. Synthesising a
 * capacity level from the percentage would change shutdown behaviour:
 * BatteryService::shouldShutdownLocked() shuts down as soon as the HAL reports
 * CRITICAL, whereas its UNSUPPORTED fallback only shuts down at level 0.
 * config_criticalBatteryWarningLevel (5) drives the warning UI, not shutdown,
 * so reusing it here would power the phone off at 5%.
 */
extern "C" IHealth* HIDL_FETCH_IHealth(const char* instance) {
    if (instance != "default"sv) {
        return nullptr;
    }

    auto config = std::make_unique<healthd_config>();
    InitHealthdConfig(config.get());

    config->batteryFullChargePath = ::android::String8(kFgChargeFull);
    config->batteryFullChargeDesignCapacityUahPath = ::android::String8(kFgChargeFullDesign);
    config->batteryCycleCountPath = ::android::String8(kFgCycleCount);
    config->energyCounter = TalkmanEnergyCounter;

    return new Health(std::move(config));
}
