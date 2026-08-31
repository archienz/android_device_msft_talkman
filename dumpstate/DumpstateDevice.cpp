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

#define LOG_TAG "dumpstate"

#include "DumpstateDevice.h"

#include <dirent.h>
#include <errno.h>
#include <fnmatch.h>
#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/sysmacros.h>
#include <unistd.h>

#include <log/log.h>

#include "DumpstateUtil.h"

using android::os::dumpstate::CommandOptions;
using android::os::dumpstate::DumpFileToFd;
using android::os::dumpstate::RunCommandToFd;

namespace android {
namespace hardware {
namespace dumpstate {
namespace V1_0 {
namespace implementation {

namespace {

/* Health 2.1 / BatteryService / QA-CHECKLIST §1.2: battery + bms + usb + dc (Qi). */
static const char* const kRequiredPsys[] = {"battery", "bms", "usb", "dc"};
static constexpr size_t kRequiredPsyCount =
        sizeof(kRequiredPsys) / sizeof(kRequiredPsys[0]);

static void DumpPowerSupply(int fd, const char* psy) {
    char dirpath[128];
    snprintf(dirpath, sizeof(dirpath), "/sys/class/power_supply/%s", psy);

    DIR* dir = opendir(dirpath);
    if (dir == nullptr) {
        dprintf(fd, "------ power_supply %s: %s ------\n", psy, strerror(errno));
        return;
    }

    char title[96];
    char path[192];
    snprintf(path, sizeof(path), "%s/uevent", dirpath);
    snprintf(title, sizeof(title), "power_supply %s/uevent", psy);
    DumpFileToFd(fd, title, path);

    struct dirent* de;
    while ((de = readdir(dir)) != nullptr) {
        if (de->d_name[0] == '.' || strcmp(de->d_name, "uevent") == 0) {
            continue;
        }
        snprintf(path, sizeof(path), "%s/%s", dirpath, de->d_name);
        struct stat st;
        if (lstat(path, &st) != 0 || S_ISDIR(st.st_mode) || S_ISLNK(st.st_mode)) {
            continue;
        }
        if (access(path, R_OK) != 0) {
            continue;
        }
        snprintf(title, sizeof(title), "power_supply %s/%s", psy, de->d_name);
        DumpFileToFd(fd, title, path);
    }
    closedir(dir);
}

static void DumpTalkmanPowerSupply(int fd) {
    bool dumped[kRequiredPsyCount] = {};

    DIR* cls = opendir("/sys/class/power_supply");
    if (cls == nullptr) {
        dprintf(fd, "------ /sys/class/power_supply: %s ------\n", strerror(errno));
    } else {
        dprintf(fd, "------ /sys/class/power_supply ------\n");
        struct dirent* de;
        while ((de = readdir(cls)) != nullptr) {
            if (de->d_name[0] == '.') {
                continue;
            }
            dprintf(fd, "%s\n", de->d_name);
        }
        rewinddir(cls);
        while ((de = readdir(cls)) != nullptr) {
            if (de->d_name[0] == '.') {
                continue;
            }
            DumpPowerSupply(fd, de->d_name);
            for (size_t i = 0; i < kRequiredPsyCount; ++i) {
                if (strcmp(de->d_name, kRequiredPsys[i]) == 0) {
                    dumped[i] = true;
                }
            }
        }
        closedir(cls);
    }

    for (size_t i = 0; i < kRequiredPsyCount; ++i) {
        if (!dumped[i]) {
            DumpPowerSupply(fd, kRequiredPsys[i]);
        }
    }
}

/* Read-only: a write to talkman-cci-scan/scan starts a CCI bus walk. */
static const char* const kCciScanDebugfs[] = {
        "/sys/kernel/debug/talkman-cci-scan/scan",
        "/sys/kernel/debug/talkman_cci_scan/scan",
        "/d/talkman-cci-scan/scan",
};

/* genfs_contexts / file_contexts sysfs_camera prefixes (msm8992-camera.dtsi). */
static const char* const kCamssSysfs[] = {
        "/sys/devices/soc.0/fd8c0000.qcom,msm-cam",
        "/sys/devices/soc.0/fda0c000.qcom,cci",
        "/sys/devices/soc.0/fda0ac00.qcom,csiphy",
        "/sys/devices/soc.0/fda0b000.qcom,csiphy",
        "/sys/devices/soc.0/fda0b400.qcom,csiphy",
        "/sys/devices/soc.0/fda08000.qcom,csid",
        "/sys/devices/soc.0/fda08400.qcom,csid",
        "/sys/devices/soc.0/fda08800.qcom,csid",
        "/sys/devices/soc.0/fda08c00.qcom,csid",
        "/sys/devices/soc.0/fda0a000.qcom,ispif",
        "/sys/devices/soc.0/fda00000.qcom,irqrouter",
        "/sys/devices/soc.0/fda04000.qcom,cpp",
        "/sys/devices/soc.0/fda10000.qcom,vfe",
        "/sys/devices/soc.0/fda14000.qcom,vfe",
        "/sys/devices/soc.0/fda1c000.qcom,jpeg",
        "/sys/devices/soc.0/fdaa0000.qcom,jpeg",
        "/sys/module/msm_camera",
        "/sys/module/msm_cci",
        "/sys/module/msm_csid",
        "/sys/module/msm_csiphy",
        "/sys/module/msm_isp",
        "/sys/module/msm_cpp",
        "/sys/module/msm_jpeg",
};

/*
 * ice5lp2k CDONE + hd3ss460 mux (mmo-usbc.c). Root DT nodes land on
 * platform; soc.0 is the other of_platform parent. Missing = ENOENT.
 */
static const char* const kUsbcSysfs[] = {
        "/sys/devices/platform/ice5lp2k/cdone",
        "/sys/devices/soc.0/ice5lp2k/cdone",
        "/sys/devices/platform/hd3ss460/mux",
        "/sys/devices/soc.0/hd3ss460/mux",
};

static void DumpReadableDir(int fd, const char* title, const char* dirpath) {
    DIR* dir = opendir(dirpath);
    if (dir == nullptr) {
        dprintf(fd, "------ %s (%s): %s ------\n", title, dirpath, strerror(errno));
        return;
    }

    dprintf(fd, "------ %s (%s) ------\n", title, dirpath);

    char path[256];
    char file_title[192];
    struct dirent* de;
    while ((de = readdir(dir)) != nullptr) {
        if (de->d_name[0] == '.' || strcmp(de->d_name, "notes") == 0) {
            continue;
        }
        snprintf(path, sizeof(path), "%s/%s", dirpath, de->d_name);
        struct stat st;
        if (lstat(path, &st) != 0) {
            continue;
        }
        if (S_ISDIR(st.st_mode)) {
            if (strcmp(de->d_name, "parameters") == 0) {
                snprintf(file_title, sizeof(file_title), "%s/%s", title, de->d_name);
                DumpReadableDir(fd, file_title, path);
            }
            continue;
        }
        if (S_ISLNK(st.st_mode) || !S_ISREG(st.st_mode)) {
            continue;
        }
        if (access(path, R_OK) != 0) {
            continue;
        }
        snprintf(file_title, sizeof(file_title), "%s/%s", title, de->d_name);
        DumpFileToFd(fd, file_title, path);
    }
    closedir(dir);
}

/* List dirpath/pattern (path + size). Missing dir or no match: ENOENT.
 * dump_contents is for text XML only — never cat .kar firmware. */
static void DumpGlobListing(int fd, const char* title, const char* dirpath,
                            const char* pattern, bool dump_contents) {
    DIR* dir = opendir(dirpath);
    if (dir == nullptr) {
        dprintf(fd, "------ %s (%s/%s): %s ------\n", title, dirpath, pattern,
                strerror(errno));
        return;
    }

    dprintf(fd, "------ %s (%s/%s) ------\n", title, dirpath, pattern);

    int hits = 0;
    struct dirent* de;
    while ((de = readdir(dir)) != nullptr) {
        if (de->d_name[0] == '.') {
            continue;
        }
        if (fnmatch(pattern, de->d_name, 0) != 0) {
            continue;
        }

        char path[256];
        int n = snprintf(path, sizeof(path), "%s/%s", dirpath, de->d_name);
        if (n < 0 || n >= (int)sizeof(path)) {
            continue;
        }

        struct stat st;
        if (lstat(path, &st) != 0) {
            dprintf(fd, "%s: %s\n", path, strerror(errno));
            continue;
        }

        /* Listing: regular files or char devices (/dev/video*). Never cat devices. */
        if (S_ISCHR(st.st_mode)) {
            dprintf(fd, "%s  char %d:%d\n", path, major(st.st_rdev),
                    minor(st.st_rdev));
            hits++;
            continue;
        }
        if (!S_ISREG(st.st_mode)) {
            continue;
        }

        dprintf(fd, "%s  %lld\n", path, (long long)st.st_size);
        hits++;
        if (dump_contents && access(path, R_OK) == 0) {
            DumpFileToFd(fd, title, path);
        }
    }
    closedir(dir);

    if (hits == 0) {
        dprintf(fd, "%s: %s\n", pattern, strerror(ENOENT));
    }
}

static void DumpTalkmanCameraCciUsbc(int fd) {
    for (size_t i = 0; i < sizeof(kCciScanDebugfs) / sizeof(kCciScanDebugfs[0]); ++i) {
        DumpFileToFd(fd, "talkman-cci-scan", kCciScanDebugfs[i]);
    }

    for (size_t i = 0; i < sizeof(kCamssSysfs) / sizeof(kCamssSysfs[0]); ++i) {
        DumpReadableDir(fd, "CAMSS", kCamssSysfs[i]);
    }

    for (size_t i = 0; i < sizeof(kUsbcSysfs) / sizeof(kUsbcSysfs[0]); ++i) {
        DumpFileToFd(fd, "USB-C", kUsbcSysfs[i]);
    }

    DumpGlobListing(fd, "OIS firmware", "/vendor/firmware", "bu24210*.kar", false);
    DumpGlobListing(fd, "camera XML", "/vendor/etc/camera", "*.xml", true);

    /* qpnp-flash-led + gpio-leds torch (ueventd.talkman.rc). Missing = ENOENT. */
    {
        DIR* leds = opendir("/sys/class/leds");
        if (leds == nullptr) {
            dprintf(fd, "------ /sys/class/leds: %s ------\n", strerror(errno));
        } else {
            struct dirent* de;
            while ((de = readdir(leds)) != nullptr) {
                if (de->d_name[0] == '.') {
                    continue;
                }
                if (strstr(de->d_name, "torch") == nullptr &&
                    strstr(de->d_name, "flash") == nullptr) {
                    continue;
                }
                char ledpath[192];
                snprintf(ledpath, sizeof(ledpath), "/sys/class/leds/%s", de->d_name);
                DumpReadableDir(fd, "torch/flash LED", ledpath);
            }
            closedir(leds);
        }
    }

    /* Node listing only — does not open V4L2 or imply a working camera. */
    DumpGlobListing(fd, "/dev/video*", "/dev", "video*", false);
}

}  // namespace

// Methods from ::android::hardware::dumpstate::V1_0::IDumpstateDevice follow.
Return<void> DumpstateDevice::dumpstateBoard(const hidl_handle& handle) {
    if (handle == nullptr || handle->numFds < 1) {
        ALOGE("no FDs\n");
        return Void();
    }

    int fd = handle->data[0];
    if (fd < 0) {
        ALOGE("invalid FD: %d\n", handle->data[0]);
        return Void();
    }

    DumpFileToFd(fd, "INTERRUPTS", "/proc/interrupts");
    DumpFileToFd(fd, "RPM Stats", "/d/rpm_stats");
    DumpFileToFd(fd, "Power Management Stats", "/d/rpm_master_stats");
    RunCommandToFd(fd, "SUBSYSTEM TOMBSTONES", {"ls", "-l", "/data/tombstones/ramdump"} , CommandOptions::AS_ROOT);
    DumpFileToFd(fd, "BAM DMUX Log", "/d/ipc_logging/bam_dmux/log");
    DumpFileToFd(fd, "SMD Log", "/d/ipc_logging/smd/log");
    DumpFileToFd(fd, "SMD PKT Log", "/d/ipc_logging/smd_pkt/log");
    DumpFileToFd(fd, "IPC Router Log", "/d/ipc_logging/ipc_router/log");
    RunCommandToFd(fd, "ION HEAPS", {"/system/bin/sh", "-c", "for d in $(ls -d /d/ion/*); do for f in $(ls $d); do echo --- $d/$f; cat $d/$f; done; done"});
    DumpFileToFd(fd, "dmabuf info", "/d/dma_buf/bufinfo");
    DumpTalkmanPowerSupply(fd);
    DumpTalkmanCameraCciUsbc(fd);
    RunCommandToFd(fd, "Temperatures", {"/system/bin/sh", "-c", "for f in emmc_therm msm_therm pa_therm0 xo_therm ; do echo -n \"$f : \" ; cat /sys/class/hwmon/hwmon2/device/$f ; done ; for f in `ls /sys/class/thermal` ; do type=`cat /sys/class/thermal/$f/type` ; temp=`cat /sys/class/thermal/$f/temp` ; echo \"$type: $temp\" ; done"}, CommandOptions::AS_ROOT);
    DumpFileToFd(fd, "dmesg-ramoops-0", "/sys/fs/pstore/dmesg-ramoops-0");
    DumpFileToFd(fd, "dmesg-ramoops-1", "/sys/fs/pstore/dmesg-ramoops-1");
    DumpFileToFd(fd, "LITTLE cluster time-in-state", "/sys/devices/system/cpu/cpu0/cpufreq/stats/time_in_state");
    RunCommandToFd(fd, "LITTLE cluster cpuidle", {"/system/bin/sh", "-c", "for d in $(ls -d /sys/devices/system/cpu/cpu0/cpuidle/state*); do echo \"$d: `cat $d/name` `cat $d/desc` `cat $d/time` `cat $d/usage`\"; done"}, CommandOptions::AS_ROOT);
    DumpFileToFd(fd, "big cluster time-in-state", "/sys/devices/system/cpu/cpu4/cpufreq/stats/time_in_state");
    RunCommandToFd(fd,"big cluster cpuidle", {"/system/bin/sh", "-c", "for d in $(ls -d /sys/devices/system/cpu/cpu4/cpuidle/state*); do echo \"$d: `cat $d/name` `cat $d/desc` `cat $d/time` `cat $d/usage`\"; done"}, CommandOptions::AS_ROOT);

    return Void();
}

}  // namespace implementation
}  // namespace V1_0
}  // namespace dumpstate
}  // namespace hardware
}  // namespace android
