# talkman

This repository is the device tree for the Lumia 950.
The device codename is talkman.
This repository is not for the Lumia 950 XL.
The Lumia 950 XL codename is cityman.
Do not use cityman procedures for talkman.

## Purpose

This repository is the archienz working tree for LineageOS 18.1 on talkman.
The branch is lineage-18.1-talkman.
All device-tree work stays on this fork.
Do not push to Android4Lumia950.

The full first-ship data is in [FIRST-SHIP.md](FIRST-SHIP.md).

WARNING: Do not use a cityman tag.

WARNING: Do not install Image.gz-dtb if Image.gz-dtb has one DTB and that DTB is a cityman DTB.

## What we are doing

We bring up missing hardware on talkman.
We fix bugs in the device tree that is already in this repository.
We add security patches that apply to this tree.
We prepare kernel governor and STACKPROTECTOR_STRONG changes for when the kernel is on archienz.
Camera work waits for a DPP dump.

ASD-STE100 updates this README when the facts change.

## What we have done

### Pull request 1

https://github.com/archienz/android_device_msft_talkman/pull/1

The speaker path uses QUAT_MI2S_RX.
The speaker amplifier is TAS2552.
Set TAS2552 Volume to 18.
The torch HAL writes 0 or 255 to led::flash_torch.
Add rild to PRODUCT_PACKAGES.
The headphone path uses SLIMBUS_5_RX.
Set persist.speaker.prot.enable to false.
The speaker path does not use SD3.

### Pull request 2

https://github.com/archienz/android_device_msft_talkman/pull/2

Pull request 2 adds FIRST-SHIP.md and README.md on branch docs/first-ship.

### Pull request 3

https://github.com/archienz/android_device_msft_talkman/pull/3

Set qseecom to 0660.
Set diag logs to 0770.
Set TARGET_OTA_ASSERT_DEVICE to talkman only.
Remove bullhead and angler from TARGET_OTA_ASSERT_DEVICE.

### Pull request 4

https://github.com/archienz/android_device_msft_talkman/pull/4

Set AUDIO_FEATURE_ENABLED_SPKR_PROTECTION to false.

## Not done

Camera is not implemented. You must have SMIApp and a DPP dump.
The voice front-end for quat is not implemented.
tinymix on the device after brunch of pull request 1 is unproven.
The device boot log must show SMEM 0xfb and hw_platform 26. These values are unproven.
Kernel, vendor, and lk2nd are not on the archienz fork.
The Quick Settings torch is off until the camera function is complete.
