# Talkman NFC configs

Chip is NXP **PN547** (keep — not a bullhead leftover). Kernel side lives in
`android_kernel_mmo_msm8994` (`lineage-18.1-talkman`): `nq-nci` binds
`/dev/pn547` on I²C6.

Factory EEPROM / RF note: `../docs/nfc-pn547.md` (ACPI `_DSM` function 3,
board name `Talkman`). No FeliCa UART / `snfc_*`. `VZW_FEATURE_ENABLE=0`.

`init.talkman.nfc.rc` chmod/chowns `/dev/pn547`, symlinks `/dev/pn54x` for
the HAL default node, and creates `/data/nfc` + `/data/vendor/nfc`.

These two files are the userspace half:

| File | Why it differs from the old overlay |
|---|---|
| `libnfc-nxp.conf` | `/dev/pn547`, PN547C2 (`NXP_NFC_CHIP=0x01`), BBCLK2 PLL 19.2, factory `A0 0D` RF |
| `libnfc-nci.conf` | `LEGACY_MIFARE_READER=1`, Kovio poll `0x77`, presence-check 0 |

NTAG / Type 2 and ISO-DEP (Wallet) work from the kernel alone.
Mifare Classic 1K NDEF needs these configs.

Antenna is the back cover, Qi / center — not the top edge.
Leave extra NFC reader apps closed; two clients on the PN547 can
wedge `com.android.nfc`.
