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
Copy roomservice.xml to .repo/local_manifests/roomservice.xml so brunch uses the archienz device tree.

WARNING: Do not use a cityman tag.

WARNING: Do not install Image.gz-dtb if Image.gz-dtb has one DTB and that DTB is a cityman DTB.

## What we have done

These functions are on lineage-18.1-talkman.

The speaker path uses QUAT_MI2S_RX.
The speaker amplifier is TAS2552.
Set TAS2552 Volume to 18.
The torch HAL writes 0 or 255 to led::flash_torch.
Set genfscon for sysfs /class/leds to sysfs_leds.
Set file_contexts for /sys/class/leds(/.*)? to sysfs_leds.
The blanket write for hal_light to sysfs is gone.
The genfscon commit is fd50fbb.
The file_contexts commit is 4abb92c.
The PRODUCT_PACKAGES list includes rild.
Set qseecom to 0660.
Set diag to 0770.
Set TARGET_OTA_ASSERT_DEVICE to talkman only.
Set AUDIO_FEATURE_ENABLED_SPKR_PROTECTION to false.
The GNSS debug function uses std::min.
Dumpstate does not use DumpFileToFd for ipc_logging.
librmnetctl does not free the same object two times.
The GnssNavigationMessage length uses std::min.
The clamp size is sizeof(message->data).
The clamp size is not 40.
The file init.talkman.rc does not contain LGE SKU wifi.
The file init.talkman.rc does not contain IMS QMI.
The GnssNavigationMessage commit is b0d3883.
The GnssNavigationMessage commit is under HEAD d572733.
The QCamera2 recode is on lineage-18.1-talkman.
The QCamera2 recode commit is 73947d2.
The QCamera2 recode sets probe, torch, and msm8992.
The SMIApp provider is disabled.
The SMIApp commit is 80dde95.
The QCamera2 change sets JPEG, ION, and vendor-module.
The QCamera2 JPEG commit is d572733.
The HEAD commit is d572733.

## What we are doing

We bring up the lights and torch functions on talkman.
We bring up the camera function. You must have a DPP dump.
We bring up SELinux. SELinux is still permissive.
SELINUX_IGNORE_NEVERALLOWS stays.

## Not done

Camera is not implemented. You must have SMIApp and a DPP dump.
The camera function does not work.
The Quick Settings torch is off until the camera function is complete.
The voice front-end for quat is not implemented.
tinymix on the device is unproven.
The device boot log must show SMEM 0xfb and hw_platform 26. These values are unproven.
Kernel, vendor, and lk2nd are not on the archienz fork.
SELinux is not enforcing.
