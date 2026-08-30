# talkman

This repository is the device tree for the Lumia 950.
The device codename is talkman.
This repository is not for the Lumia 950 XL.
The Lumia 950 XL codename is cityman.
Do not use cityman procedures for talkman.

The Android tree is Android4Lumia950.
The Android version is LineageOS 18.1.
The device branch is lineage-18.1-talkman.

The full first-ship data is in [FIRST-SHIP.md](FIRST-SHIP.md).

WARNING: Do not use a cityman tag.

WARNING: Do not install Image.gz-dtb if Image.gz-dtb has one DTB and that DTB is a cityman DTB.

## Implemented

The functions below are in pull requests on the archienz fork.
These functions are not on Android4Lumia950.

### Pull request 1

The pull request is a draft.
The branch name is cursor/first-ship-mixer-lights-rild-4b97.
The URL is https://github.com/archienz/android_device_msft_talkman/pull/1

The speaker path uses QUAT_MI2S_RX.
The speaker amplifier is TAS2552.
Set TAS2552 Volume to 18.
The torch HAL writes 0 or 255 to led::flash_torch.
Add rild to PRODUCT_PACKAGES.
The headphone path uses SLIMBUS_5_RX.
Set persist.speaker.prot.enable to false.
The speaker path does not use SD3.

### Pull request 2

The pull request is a draft.
The branch name is docs/first-ship.
The URL is https://github.com/archienz/android_device_msft_talkman/pull/2
Pull request 2 adds FIRST-SHIP.md and README.md.

### Pull request 3

The CVE pull request is not stacked on pull request 1.
The branch name is cursor/tighten-qseecom-diag-ota-57b7.
The URL is https://github.com/archienz/android_device_msft_talkman/pull/3

Set qseecom to 0660.
Set diag to 0770.
Set TARGET_OTA_ASSERT_DEVICE to talkman only.
Remove bullhead from TARGET_OTA_ASSERT_DEVICE.
Remove angler from TARGET_OTA_ASSERT_DEVICE.

## In progress and unproven

The device boot log must show SMEM 0xfb. This value is unproven.
The device boot log must show hw_platform 26. This value is unproven.
tinymix on the device after brunch of pull request 1 is unproven.
The kernel governor change from PERFORMANCE to interactive is prepared.
STACKPROTECTOR_STRONG is prepared.
There is no archienz kernel fork at this time.
The Quick Settings torch is off until the camera function is complete.
HIDL 2.0 has no Flashlight interface.

## Not implemented

Camera is not implemented. You must have SMIApp and a DPP dump.
The voice front-end for quat is not implemented. This function is in a later change.
Kernel, vendor, and lk2nd are not on the archienz fork.
Do not push these trees to Android4Lumia950.
