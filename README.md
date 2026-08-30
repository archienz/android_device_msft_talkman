# talkman

## Purpose

This repository is the archienz device tree for the Lumia 950.
The device codename is talkman.
The Android version is LineageOS 18.1.
The device branch is lineage-18.1-talkman.
This repository is not for the Lumia 950 XL.
The Lumia 950 XL codename is cityman.
Do not use cityman procedures for talkman.
Work stays on the archienz fork.
Do not push to Android4Lumia950.

The full first-ship data is in [FIRST-SHIP.md](FIRST-SHIP.md).

WARNING: Do not use a cityman tag.

WARNING: Do not install Image.gz-dtb if Image.gz-dtb has one DTB and that DTB is a cityman DTB.

## Work

The first-ship work adds the speaker path, the torch HAL, and rild.
The CVE work sets qseecom, diag, and TARGET_OTA_ASSERT_DEVICE.
When the kernel is forked, set the governor to interactive.
When the kernel is forked, set STACKPROTECTOR_STRONG.
Camera is a later function. You must have a DPP dump.

## Completed work

### Pull request 1

The URL is https://github.com/archienz/android_device_msft_talkman/pull/1
The branch name is cursor/first-ship-mixer-lights-rild-4b97.
The speaker path uses QUAT_MI2S_RX.
The speaker amplifier is TAS2552.
Set TAS2552 Volume to 18.
The torch HAL writes 0 or 255 to led::flash_torch.
Add rild to PRODUCT_PACKAGES.

### Pull request 2

The URL is https://github.com/archienz/android_device_msft_talkman/pull/2
The branch name is docs/first-ship.
Pull request 2 adds FIRST-SHIP.md and README.md.

### Pull request 3

The URL is https://github.com/archienz/android_device_msft_talkman/pull/3
The branch name is cursor/tighten-qseecom-diag-ota-57b7.
Set qseecom to 0660.
Set diag to 0770.
Set TARGET_OTA_ASSERT_DEVICE to talkman only.

### Pull request 4

The URL is https://github.com/archienz/android_device_msft_talkman/pull/4
The branch name is cursor/disable-spkr-protection-4683.
Set AUDIO_FEATURE_ENABLED_SPKR_PROTECTION to false.

## Not done

Camera is not done.
The voice front-end for quat is not done.
tinymix on the device is not proven.
The boot log SMEM 0xfb is unproven.
The boot log hw_platform 26 is unproven.
Kernel, vendor, and lk2nd forks are not on archienz.
