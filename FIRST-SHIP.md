# First-ship data for talkman

This document gives the first-ship data for the Lumia 950.
The device codename is talkman.
This document is not for the Lumia 950 XL.
The Lumia 950 XL codename is cityman.
Do not use cityman procedures for talkman.
The dashboard summary is in [README.md](README.md).

## Device and trees

The device is the Lumia 950 (talkman).
The SoC is MSM8992.
The Android tree is Android4Lumia950.
The Android version is LineageOS 18.1.
The current branch is lineage-18.1-talkman.
Do not use a cursor branch.
The roomservice device project is archienz/android_device_msft_talkman.
The revision is lineage-18.1-talkman.

The local clone is at C:\Users\nizb0\src\android_device_msft_talkman.
The origin remote is the archienz fork.
The upstream remote is Android4Lumia950.

Do not send first-ship changes to Android4Lumia950 at this time.
GitHub returns HTTP 403 if you write to Android4Lumia950/android_device_msft_talkman.
HTTP 403 means there is no write access.

## Functions on lineage-18.1-talkman

The speaker path uses QUAT_MI2S_RX.
The speaker amplifier is TAS2552.
Set TAS2552 Volume to 18.
Set Mute to 0 or 1.
Set Channels to One.
The name of the sound card is msm8994-tomtom-snd-card.
The headphone path uses SLIMBUS_5_RX.
Set persist.speaker.prot.enable to false.
The speaker path does not use SD3.
Set AUDIO_FEATURE_ENABLED_SPKR_PROTECTION to false.

LIGHT_ID_FLASHLIGHT writes to /sys/class/leds/led::flash_torch/brightness.
Write 0 to set the torch to OFF.
Write 255 to set the torch to ON.
Set genfscon for sysfs /class/leds to sysfs_leds.
Set file_contexts for /sys/class/leds(/.*)? to sysfs_leds.
The blanket write for hal_light to sysfs is gone.
The genfscon commit is fd50fbb.
The file_contexts commit is 4abb92c.
HIDL 2.0 has no Flashlight interface.
The Quick Settings torch is off until the camera function is complete.

The PRODUCT_PACKAGES list includes rild.
Do not start rild in init.talkman.rc.

Set qseecom to 0660.
Set diag to 0770.
Set TARGET_OTA_ASSERT_DEVICE to talkman only.
Do not include bullhead in TARGET_OTA_ASSERT_DEVICE.
Do not include angler in TARGET_OTA_ASSERT_DEVICE.

The GNSS debug function uses std::min.
The file is gnss/1.0/default/GnssDebug.cpp.
Dumpstate does not use DumpFileToFd for ipc_logging.
librmnetctl does not free the same object two times.
The GnssNavigationMessage length uses std::min.
The clamp size is sizeof(message->data).
The clamp size is not 40.
The file init.talkman.rc does not contain LGE SKU wifi.
The file init.talkman.rc does not contain IMS QMI.
The GnssNavigationMessage commit is b0d3883.
The GnssNavigationMessage commit is under HEAD da2d20d.
The QCamera2 recode is on lineage-18.1-talkman.
The QCamera2 recode commit is 73947d2.
The QCamera2 recode sets probe, torch, and msm8992.
The SMIApp provider is disabled.
The SMIApp commit is 80dde95.
The QCamera2 change sets JPEG, ION, and vendor-module.
The QCamera2 JPEG commit is d572733.
The file device.mk does not include camera.device@1.0-impl.
The device.mk commit is 49965d7.
The file flash-autofocus.xml stays.
The ION mmap file descriptors are closed.
The ION mmap commit is 1eb58d3.
The file init.talkman.rc does not contain qcamerasvr.
The file init.talkman.rc does not contain mm-qcamera-daemon.
The file proprietary-blobs.txt does not contain qcamerasvr.
The file proprietary-blobs.txt does not contain mm-qcamera-daemon.
The init camera daemon commit is eb97ddb.
The last-code parent is e445663.
The last code is da2d20d.
The HEAD commit is da2d20d.
CVE pass 5 landed at c8ac257.
The file init.talkman.rc sets chmod 0700 on /sys/kernel/debug.
ATFWD is disabled unless persist.radio.atfwd.start=true.
The torch HAL is complete.
The sysfs_leds labels are complete.
The radio notes file is radio/README.md.
The radio notes file stays at 539d08c.
The file radio/README.md exists.
It holds MODEM_FS1, MODEM_FS2, MODEM_FSC, MODEM_FSG, and DPP restore notes.
modem.img stays TALKMAN_LTE_ROW.
This is not a device-tree change.
Do not add service rild, radio.img, IMS, or Dual SIM.
The e445663 change dropped /system/bin/imsdatadaemon and /system/bin/imsqmidaemon from proprietary-blobs.txt only.
The file proprietary-blobs.txt still has ims_rtp_daemon.
The file proprietary-blobs.txt still has embms jars.
The file proprietary-blobs.txt still has rcs jars.
The file proprietary-blobs.txt still has QCRIL.
The file proprietary-blobs.txt still has qmuxd.
The file proprietary-blobs.txt still has rild.
The da2d20d change dropped qpnp-flash-led-26 genfscon from sepolicy/genfs_contexts.
The sysfs_leds label for /class/leds stays.

## Functions that are not complete

Camera is not implemented. You must have SMIApp and a DPP dump.
The camera function does not work.
The voice front-end for quat is not implemented.
Additional flash code in the kernel is not in this tree. The Harmony kernel already has TAS, quat DAI, and torch DTS.

## In progress and unproven

tinymix on the device is unproven.
The kernel governor change from PERFORMANCE to interactive is prepared.
STACKPROTECTOR_STRONG is prepared.
There is no archienz kernel fork at this time.
SELinux is still permissive. SELinux is not enforcing.
SELINUX_IGNORE_NEVERALLOWS stays.
We bring up the camera function. You must have a DPP dump.
The camera function does not work.
We bring up SELinux.

## Flash

Use the installer from Android4Lumia950/installer.
Use the main branch of the installer.

WARNING: Do not use a cityman tag.

WARNING: Do not install Image.gz-dtb if Image.gz-dtb has one DTB and that DTB is a cityman DTB.

## Boot

The LK picker uses msm-id.
If the msm-id is not correct, the LK picker must stop.
The shipped MBN is lk1st.
The lk1st commit is ff6749af.
The shipped MBN is the same as the picker at HEAD.
Harmony DTB0 for talkman has msm-id 0xfb.
Harmony DTB0 for talkman has board-id 26.

You must get a boot log from the device.
The boot log must show SMEM 0xfb.
The boot log must show hw_platform 26.
The SMEM value 0xfb on the device is unproven.
The hw_platform value 26 on the device is unproven.
