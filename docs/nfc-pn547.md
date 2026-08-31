# Talkman NFC — NXP PN547 (keep)

**Chipset stays PN547.** This file is the factory EEPROM
extract from WOA ACPI, plus the FeliCa/snfc and VZW checks. It is not a firmware
blob and it is not a chipset swap.

Source of hardware truth: `woa/Lumia950XLPkg/AcpiTables/8992/src/SSDT.asl`
`Device (NFC1)`. PLAN.md's "pn547 is leftover" line is wrong.

---

## 0. Law

| | |
|---|---|
| Chip | **NXP PN547** (`PNP0547` / `PN547` / `ACPIPN547`). Keep. |
| Swap | **Do not** change `BOARD_NFC_CHIPSET` to pn548 / pn553 / pn7150 / snfc. That would be a sim. |
| FeliCa / snfc | Talkman has **no** Sony FeliCa UART. `snfc_*` device nodes are gone. |
| VZW | Talkman is not a Verizon SKU. `VZW_FEATURE_ENABLE=0x00`. |
| Cityman | 8994 SSDT EEPROM is the same RF stream with ASCII `Cityman`. Do not mix the **name** field. RF bytes after offset 8 are identical. |

---

## 1. Identity

| | Talkman (Lumia 950, MSM8992) |
|---|---|
| ACPI | `\_SB.NFC1` |
| `_HID` | `PNP0547` |
| `_CID` | `PN547`, `ACPIPN547` |
| I²C | **0x28** on `I2C6` (BLSP1 QUP6 `0xF9928000`), 400 kHz (`0x00061A80`) |
| IRQ | TLMM **29** (`0x001D`), edge high, pull-down |
| VEN | TLMM **30** (`0x001E`) — ASL `POON` / `POOF` |
| FW-download | TLMM **94** (`0x005E`) — ASL `FWON` / `FWOF` |
| Clock | BBCLK2 (`qcom,clk-src = "BBCLK2"` in `nfc.dtsi`) |
| Windows | `NXPPN547.inf` binds `ACPI\PN547`; firmware `nxppn547fw.dat`; `FirmwareMap` keys **5** and **8** |
| Linux DT | `arch/arm64/boot/dts/mmo/common/nfc.dtsi` `pn547@28`, compatible `nxp,pn547`, `qcom,nq-nci` |
| Userspace | `BOARD_NFC_CHIPSET := pn547`, `BOARD_NFC_DEVICE := "/dev/pn547"`, HAL suffix `msm8992` |

Kernel `nq-nci` node, init chmod, ueventd, and sepolicy all name `/dev/pn547`.
`nfc/init.talkman.nfc.rc` also symlinks `/dev/pn54x` because the NXP HAL still
opens that path.

---

## 2. ACPI `_DSM`

UUID `a2e7f6c4-9638-4485-9f12-6b4e20b60d63`. Query (Arg2=0, rev 1) returns
`0x0F` — functions 0–3 implemented.

| Arg2 | ASL debug | Meaning |
|---|---|---|
| 0 | `NFC _DSM QUERY` | Bitmask of functions |
| 1 | `NFC _DSM SETFWMODE` | Arg3=1: `POOF` → `FWON` → sleep 1 → `POON` → sleep 0x14. Arg3=0: same with `FWOF`. |
| 2 | `NFC _DSM SETPOWERMODE` | Arg3=1 `POON`, Arg3=0 `POOF`, sleep 0x14 |
| **3** | **`NFC _DSM EEPROM Config`** | **Returns the factory EEPROM / RF buffer below** |

Function 3 is **not** the NXP firmware download image. Firmware is
`woa/Lumia-Drivers/.../Drivers/NFC/nxppn547fw.dat` (34590 bytes). The EEPROM
buffer is clock + NXP proprietary core settings + analog RF (`A0 0D`) for this
antenna.

Re-extract:

```
python tools/extract_nfc_eeprom.py
```

---

## 3. EEPROM header

ASL: `Return (Buffer (0x03CA) { ... })`. iasl listed **968** initializers
(`0x0000`–`0x03C7`). ACPI pads the remaining **2** bytes with `0x00` → **970**
bytes.

| Field | Offset | Talkman value |
|---|---|---|
| Board name | `0x00`–`0x07` | ASCII `Talkman` + NUL |
| Pad | `0x08`–`0x0A` | `00 00 00` |
| Flag | `0x0B` | `0x20` (same on cityman) |
| FW major.minor | `0x0C`–`0x0D` | **`08 01`** — PN547 **8.1.x**, matches `NXPPN547.inf` FirmwareMap `8` |
| u16LE | `0x0E`–`0x0F` | `0x0022` (unknown; same on cityman) |
| TLV stream | `0x10`–`0x03C7` | tag, len, value (NXP IDs **without** the `A0` prefix) |

SHA-256 of the 968 listed bytes:
`4ab4a2b83341c79b7d3a1c57ac2ad6a54d4d0960a6cd58e2b28c807ab640caa5`

SHA-256 of the 970-byte ACPI return (two trailing zeros):
`31953e8d482afa9e9553045cac8460611d816b9cebe46c731816b2b67c11b5d9`

Blob: `docs/nfc-pn547-talkman-eeprom.bin`

Cityman (`AcpiTables/8994/src/SSDT.asl`) differs **only** at bytes 0–3
(`City` vs `Talk`). Bytes `0x08`–end are identical. RF is shared; the board
**name** is not.

---

## 4. Core / clock TLVs (offset `0x10`)

146 TLVs total: 16 core + 130× tag `0x0D` (RF). Map each core tag to NXP
proprietary `A0 xx` as used by `libnfc-nxp.conf`.

| Off | Tag | NXP ID | Len | Value | Note |
|---|---|---|---|---|---|
| 0010 | `02` | `A0 02` | 1 | `01` | Clock source. libnfc-nxp.conf currently `NXP_SYS_CLK_SRC_SEL=0x02` (PLL). EEPROM `01` is the Windows encoding (XTAL in the HAL enum). Kernel still feeds **BBCLK2**. Do not flip PLL vs XTAL without a scope. |
| 0013 | `03` | `A0 03` | 1 | `11` | Clock / clk-req bitfield. Conf uses `NXP_SYS_CLK_FREQ_SEL=0x02` (19.2 MHz). |
| 0016 | `04` | `A0 04` | 1 | `01` | |
| 0019 | `06` | `A0 06` | 1 | `01` | |
| 001C | `0E` | `A0 0E` | 1 | `01` | |
| 001F | `11` | `A0 11` | 4 | `CD 67 22 01` | |
| 0025 | `12` | `A0 12` | 1 | `00` | |
| 0028 | `40` | `A0 40` | 1 | `01` | Tag detector |
| 002B | `41` | `A0 41` | 1 | `04` | Tag detector |
| 002E | `42` | `A0 42` | 1 | `19` | |
| 0031 | `43` | `A0 43` | 1 | `00` | Tag detector |
| 0034 | `61` | `A0 61` | 1 | `00` | |
| 0037 | `5E` | `A0 5E` | 1 | `01` | Matches current `NXP_CORE_CONF_EXTN` |
| 003A | `CD` | `A0 CD` | 1 | `0F` | |
| 003D | `EC` | `A0 EC` | 1 | `01` | Wired mode. Matches conf. |
| 0040 | `ED` | `A0 ED` | 1 | `00` | Wired mode. Conf still has `A0 ED 01 01` — leftover. |

---

## 5. RF `0x0D` (NXP `A0 0D`)

130 analog records. First value byte is RF mode; second is a PN547 analog
register. libnfc-nxp.conf `NXP_RF_CONF_BLK_1` is still the **Sony sumire NFC-A
106-only** subset (modes `0x32` TX / `0x34` RX). Talkman factory data covers
poll/listen A/B/F/15693 and more.

Mode `0x32` / `0x34` overlap with Sony is close but **not** identical: Sony TX
reg `0x44` is `2D 00 02 00`; talkman is **`21 00 02 00`**. Do not keep the Sony
byte.

| Mode | Count | Role (NXP PN547 analog map) |
|---|---|---|
| `00` | 1 | NFCLD / default |
| `04` | 2 | NFC-A related |
| `06` | 12 | NFC-A / poll analog |
| `08` | 1 | |
| `0A` | 4 | |
| `0C` | 1 | |
| `10` | 1 | |
| `20` | 4 | NFC-B class |
| `22` | 2 | |
| `30` | 1 | |
| `32` | 7 | NFC-A **106 initiator TX** |
| `34` | 3 | NFC-A **106 initiator RX** |
| `35` | 1 | |
| `38` `3A` `3C` `3E` | 4+1+4+1 | NFC-F / higher-rate |
| `40`–`5C` | many | listen / CE analog |
| `6A`–`9A` | many | 15693 / extras |

`NXP_RF_CONF_BLK_2`…`_6` in tree are **empty**. Candidate CORE_SET_CONFIG
packing of every `0x0D` TLV (HAL `{20, 02, <payload_len>, <n_params>, A0, 0D, …}`)
is five blocks; **not applied** in this wave. Apply as packaging, then retune
on a tag — do not guess a different chip.

---

## 6. Firmware vs this EEPROM

| Object | Path | What it is |
|---|---|---|
| EEPROM Config | this file / `nfc-pn547-talkman-eeprom.bin` | Clock + RF + core. ACPI `_DSM` 3. |
| Windows FW | `woa/Lumia-Drivers/.../NFC/nxppn547fw.dat` | 34590-byte PN547 download. INF FirmwareMap 5 and 8. |
| Android FW array | `nfc/src/libpn547_fw.c` `gphDnldNfc_DlSequence` | **34590** bytes (`DlSeqSz` `0x871E`). Byte-identical to `nxppn547fw.dat`. |

The EEPROM extract is RF/core, not this blob. HAL still dlopens `libpn547_fw.so`.

---

## 7. Tree checks (this wave)

### PN547 keep

```
mirrors/android_device_msft_talkman/BoardConfig.mk
  BOARD_NFC_CHIPSET := pn547
  BOARD_NFC_HAL_SUFFIX := msm8992
  BOARD_NFC_DEVICE := "/dev/pn547"
```

`device.mk` still packages `NfcNci` + `libnfc-nci.conf` + `libnfc-nxp.conf`.
Vendor copies `nfc_nci.msm8992.so` (not `nfc_nci.bullhead.so`).

### FeliCa / snfc gone

`rootdir/etc/ueventd.talkman.rc` has no `snfc_*` / Sony FeliCa UART nodes.
Comment: `No FeliCa / snfc UART.` Kernel `arch/arm64/boot/dts` has no `snfc`
or `felica` compatible.

`libnfc-nxp.conf` `DEFAULT_SYS_CODE={FE,FF}` is the NXP default **NFC-F T3T**
system code (PN547 poll/listen F). That is NFC Forum Type 3, **not** a Sony
FeliCa SE. Leave it.

### VZW = 0

`nfc/libnfc-nxp.conf`: `VZW_FEATURE_ENABLE=0x00` with comment
`Talkman is not a VZW SKU.`

---

## 8. Still leftover (packaging, not chipset)

| File | Leftover |
|---|---|
| `sepolicy/file_contexts` `/system/bin/hw/nfc_hal_pn54x` | Bullhead binary name. HAL `.so` is `nfc_nci.msm8992`. |

Antenna is the back cover (Qi / center), not the top edge.

---

## 9. Full listed payload (968 bytes)

Two trailing `00` bytes exist in the ACPI object only. Hex is the iasl list.

```
0000  54 61 6C 6B 6D 61 6E 00 00 00 00 20 08 01 22 00  Talkman.... ..".
0010  02 01 01 03 01 11 04 01 01 06 01 01 0E 01 01 11  ................
0020  04 CD 67 22 01 12 01 00 40 01 01 41 01 04 42 01  ..g"....@..A..B.
0030  19 43 01 00 61 01 00 5E 01 01 CD 01 0F EC 01 01  .C..a..^........
0040  ED 01 00 0D 03 04 43 20 0D 03 04 FF 05 0D 06 06  ......C ........
0050  44 A3 90 03 00 0D 06 06 30 CF 00 08 00 0D 06 06  D.......0.......
0060  2F 8F 05 80 0C 0D 04 06 03 00 6E 0D 03 06 43 A0  /.........n...C.
0070  0D 06 06 42 00 00 FF FF 0D 06 06 41 80 00 00 00  ...B.......A....
0080  0D 03 06 37 18 0D 03 06 16 00 0D 03 06 15 00 0D  ...7............
0090  06 06 FF 05 00 00 00 0D 06 08 44 00 00 00 00 0D  ..........D.....
00A0  06 20 4A 00 00 00 00 0D 06 20 42 88 10 FF FF 0D  . J...... B.....
00B0  03 20 16 00 0D 03 20 15 00 0D 06 22 44 22 00 02  . .... ...."D"..
00C0  00 0D 06 22 2D 50 44 0C 00 0D 04 32 03 40 3D 0D  ..."-PD....2.@=.
00D0  06 32 42 F8 10 FF FF 0D 03 32 16 00 0D 03 32 15  .2B......2....2.
00E0  01 0D 03 32 0D 22 0D 03 32 14 22 0D 06 32 4A 30  ...2."..2."..2J0
00F0  07 01 1F 0D 06 34 2D 24 77 0C 00 0D 06 34 34 00  .....4-$w....44.
0100  00 E4 03 0D 06 34 44 21 00 02 00 0D 06 35 44 21  .....4D!.....5D!
0110  00 02 00 0D 06 38 4A 53 07 01 1B 0D 06 38 42 68  .....8JS.....8Bh
0120  10 FF FF 0D 03 38 16 00 0D 03 38 15 00 0D 06 3A  .....8....8....:
0130  2D 15 47 0D 00 0D 06 3C 4A 52 07 01 1B 0D 06 3C  -.G....<JR.....<
0140  42 68 10 FF FF 0D 03 3C 16 00 0D 03 3C 15 00 0D  Bh.....<....<...
0150  06 3E 2D 15 47 0D 00 0D 06 40 42 F0 10 FF FF 0D  .>-.G....@B.....
0160  03 40 0D 02 0D 03 40 14 02 0D 06 40 4A 12 07 00  .@....@....@J...
0170  00 0D 03 40 16 00 0D 03 40 15 00 0D 06 42 2D 15  ...@....@....B-.
0180  47 0D 00 0D 06 46 44 21 00 02 00 0D 06 46 2D 05  G....FD!.....F-.
0190  47 0E 00 0D 06 44 4A 33 07 01 07 0D 06 44 42 88  G....DJ3.....DB.
01A0  10 FF FF 0D 03 44 16 00 0D 03 44 15 00 0D 06 4A  .....D....D....J
01B0  44 22 00 02 00 0D 06 4A 2D 05 37 0C 00 0D 06 48  D".....J-.7....H
01C0  4A 33 07 01 07 0D 06 48 42 88 10 FF FF 0D 03 48  J3.....HB......H
01D0  16 00 0D 03 48 15 00 0D 06 4E 44 22 00 02 00 0D  ....H....ND"....
01E0  06 4E 2D 05 37 0C 00 0D 06 4C 4A 33 07 01 07 0D  .N-.7....LJ3....
01F0  06 4C 42 88 10 FF FF 0D 03 4C 16 00 0D 03 4C 15  .LB......L....L.
0200  00 0D 06 52 44 22 00 02 00 0D 06 52 2D 05 25 0C  ...RD".....R-.%.
0210  00 0D 06 50 42 90 10 FF FF 0D 06 50 4A 11 0F 01  ...PB......PJ...
0220  07 0D 03 50 16 00 0D 03 50 15 00 0D 06 56 2D 05  ...P....P....V-.
0230  9E 0C 00 0D 06 56 44 22 00 02 00 0D 06 5C 2D 05  .....VD".....\-.
0240  69 0C 00 0D 06 5C 44 21 00 02 00 0D 06 54 42 88  i....\D!.....TB.
0250  10 FF FF 0D 06 54 4A 33 07 01 07 0D 03 54 16 00  .....TJ3.....T..
0260  0D 03 54 15 00 0D 06 5A 42 90 10 FF FF 0D 06 5A  ..T....ZB......Z
0270  4A 31 07 01 07 0D 03 5A 16 00 0D 03 5A 15 00 0D  J1.....Z....Z...
0280  06 98 2F AF 05 80 0F 0D 06 9A 42 00 00 FF FF 0D  ../.......B.....
0290  06 30 44 A3 90 03 00 0D 06 6C 44 A3 90 03 00 0D  .0D......lD.....
02A0  06 6C 30 CF 00 08 00 0D 06 6C 2F 8F 05 80 0C 0D  .l0......l/.....
02B0  06 70 2F 8F 05 80 12 0D 06 70 30 CF 00 08 00 0D  .p/......p0.....
02C0  06 74 2F 8F 05 80 12 0D 06 74 30 DF 00 07 00 0D  .t/......t0.....
02D0  06 78 2F 1F 06 80 01 0D 06 78 30 3F 00 04 00 0D  .x/......x0?....
02E0  06 78 44 A2 90 03 00 0D 03 78 47 00 0D 06 7C 2F  .xD......xG...|/
02F0  AF 05 80 0F 0D 06 7C 30 CF 00 07 00 0D 06 7C 44  ......|0......|D
0300  A3 90 03 00 0D 06 7D 30 CF 00 08 00 0D 06 80 2F  ......}0......./
0310  AF 05 80 90 0D 06 80 44 A3 90 03 00 0D 06 84 2F  .......D......./
0320  AF 05 80 92 0D 06 84 44 A3 90 03 00 0D 06 88 2F  .......D......./
0330  7F 04 80 10 0D 06 88 30 5F 00 16 00 0D 03 88 47  .......0_......G
0340  00 0D 06 88 44 A1 90 03 00 0D 03 10 43 20 0D 06  ....D.......C ..
0350  6A 42 F8 10 FF FF 0D 03 6A 16 00 0D 03 6A 15 01  jB......j....j..
0360  0D 06 6A 4A 30 0F 01 1F 0D 06 8C 42 88 10 FF FF  ..jJ0......B....
0370  0D 06 8C 4A 33 07 01 07 0D 03 8C 16 00 0D 03 8C  ...J3...........
0380  15 00 0D 06 92 42 90 10 FF FF 0D 06 92 4A 31 07  .....B.......J1.
0390  01 07 0D 03 92 16 00 0D 03 92 15 00 0D 06 0A 30  ...............0
03A0  CF 00 08 00 0D 06 0A 2F 8F 05 80 0C 0D 03 0A 48  ......./.......H
03B0  10 0D 06 0A 44 A3 90 03 00 0D 03 06 48 19 0D 03  ....D.......H...
03C0  0C 48 19 0D 03 00 40 03                          .H....@.
```

---

## 10. Sources

| File | Why |
|---|---|
| `woa/Lumia950XLPkg/AcpiTables/8992/src/SSDT.asl` | Talkman `NFC1` + `_DSM` EEPROM |
| `woa/Lumia950XLPkg/AcpiTables/8994/src/SSDT.asl` | Cityman; name-only delta |
| `woa/Lumia-Drivers/.../Drivers/NFC/NXPPN547.inf` | `ACPI\PN547`, FirmwareMap 5/8 |
| `woa/Lumia-Drivers/.../Drivers/NFC/nxppn547fw.dat` | Windows FW image |
| `mirrors/android_kernel_mmo_msm8994/arch/arm64/boot/dts/mmo/common/nfc.dtsi` | Linux `pn547@28` |
| `mirrors/android_device_msft_talkman/BoardConfig.mk` | `BOARD_NFC_CHIPSET := pn547` |
| `mirrors/android_device_msft_talkman/nfc/` | conf + `libpn547_fw.c` |
| `tools/extract_nfc_eeprom.py` | Re-parse ASL → bin |

On-device: `dmesg` for `nq-nci` / `pn547`, `ls -l /dev/pn547`, `logcat -s NfcNciNxpHal:V`.
Do not mark NFC Working without a tag read on a physical talkman.
