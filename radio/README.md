# Talkman radio NV restore

The installer flashes `DATA/modem.img`. That file is TALKMAN_LTE_ROW
MPSS. Do not replace it with a cityman image or a random msm8992 image.

- sha256 `74bb66f2dd0630fdcf9a12dee3090574c907523b3c7f62d4685d7c006b6c96be`
- size 73400320 (70 MiB)
- `QC_IMAGE_VERSION_STRING=MPSS.BO.2.5.C4.3-00024`

WARNING: Restore MODEM_FS1, MODEM_FS2, MODEM_FSC, MODEM_FSG, and DPP.
If you do not restore these partitions, the modem has no IMEI and no
SIM data. The rild process cannot attach to a network.

This procedure is an installer dump restore. It is not a device-tree
change. Do not add a `service rild` stanza to `init.talkman.rc`.
Do not add `radio.img`. Do not enable IMS or Dual SIM.

## Backup

Do this step before the GPT change.

The script `partition.sh` function `dump_provisioned` copies these
partitions to the host folder `backup*`:

- MODEM_FS1
- MODEM_FS2
- MODEM_FSC
- MODEM_FSG
- DPP
- SSD

Also make a full eMMC copy with Win32DiskImager.

`partition.sh` sha1 `15b1c56e0ea88a26865ac9309a7b1a8fed05daa5`

## Restore

Do this step after TWRP and before you sideload the ROM.

The script `provision.sh` copies:

- MODEM_FS1 to modemst1
- MODEM_FS2 to modemst2
- MODEM_FSC to fsc
- MODEM_FSG to fsg
- SSD to ssd
- WLAN MAC from DPP/QCOM/WLAN.PROVISION to `/persist/wlan_mac.bin`
- Bluetooth address from DPP/QCOM/BT.PROVISION to `/persist/bdaddr.txt`

Do not omit this step. If the copy is not done, `rmt_storage` can write
empty data to modemst.

`provision.sh` sha1 `0bd60ea3b771a6645d2bd288b5f78ac3e844294e`

GNSS lock on the sideload zip is unproven.
