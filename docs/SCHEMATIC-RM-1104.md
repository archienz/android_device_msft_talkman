# Lumia 950 schematic notes — RM-1104 only

Source: Microsoft service schematic
`Lumia 950 RM-1104 / Lumia 950 Dual SIM RM-1118`, v1.0, 16.10.2015.

PDF: `docs/hardware/Lumia950-RM-1104-RM-1118-schematic.pdf`  
PNG renders used here: `docs/hardware/schematic-png/page-01.png` … `page-08.png`.

**This port is single-SIM talkman.** Use board **4VM_08r** (RM-1104).

Do **not** use Dual SIM RM-1118 / board **4VM_08d**. `page-02.png` (schematic sheet 3) marks `X2701` UIM2 as “Lumia XXX Dual SIM, RM-1118 only”. PNG `page-11` / `page-12` are Dual SIM component-finder sheets — **ignored**.

## Board vs SKU

| SKU | Board | Use |
|---|---|---|
| RM-1104 talkman | 4VM_08r | **Yes** |
| RM-1118 Dual SIM | 4VM_08d | **No** |

## PNG → sheet map (this pass)

| File | Footer | Title (RM-1104 / 4VM_08r) |
|---|---|---|
| `page-01.png` | 2 (13) | PM8994, MSM8992, Side key flex |
| `page-02.png` | 3 (13) | MSM8992, Memory, Sensor(s), SIM(s), Main/Front Cameras, UI flex |
| `page-03.png` | 4 (13) | MSM8992, PMI8994, Display/Touch, USB, IHF amplifier |
| `page-04.png` | 5 (13) | PMI8994, Audio, Battery, Wireless Charging, Vibra |
| `page-05.png` | 6 (13) | UI flex, Audio flex, Side key flex |
| `page-06.png` | 7 (13) | WLAN/BT, FM, GNSS, NFC |
| `page-07.png` | 8 (13) | RF transceiver p1 |
| `page-08.png` | 9 (13) | RF transceiver p2 |

`page-09.png` / `page-10.png` not used this pass. `page-11.png` / `page-12.png` Dual SIM finder — **do not copy**.

---

## Camera — rear on **CCI1** (`page-02.png` / sheet 3)

MSM8992 camera block (`D4000`):

| Net | Schematic |
|---|---|
| Rear CSI | CSI0 4-lane + clk (`MIPI_CSI0_LANE0..3`, `CSI0_CLK`) |
| Rear MCLK | `CAM_MCLK0` (MSM T1) → GPIO 13 / mclk0 |
| Rear I2C | **CCI1** — `CCI1_I2C_CLK` / `CCI1_I2C_DATA` (block `CCI_I2C(1)` on the SoC pinout) |
| Front (Ducati) | CSI2, `CAM_MCLK2`, `CAM_FRONT_RES_N` GPIO 104 |
| Iris (SIIRI) | CSI2 extra lanes, **CCI0**, `IRIS_CAM_RES_N` GPIO 102, `CAM_MCLK1` GPIO 14 |
| Torch | `TORCH_EN` **GPIO 12** |
| Rails | LVS1 1.8 V, L25 1.1 V, L23 2.8 V, L29 2.8 V |

Rear **CCI master 1** is on the drawing (not a guessed slave-id). 7-bit SID is **not** printed on these sheets.

EpicLPer / Hill ident agrees CCI1. DT that still has `qcom,cci-master = <0>` for the rear sensor is wrong relative to this schematic.

Torch enable is MSM **GPIO 12** (`TORCH_EN` / `FL_EN` / `FLASHLIGHT_EN` net on sheet 3).

---

## Duke AMOLED — TE GPIO_10, reset GPIO_78 (`page-03.png` / sheet 4)

Display/touch connector (`X1500` / DSI0+DSI1 split):

| Function | Net | MSM GPIO |
|---|---|---|
| Panel TE | `DISPLAY_TE` / `TE` | **GPIO 10** |
| Panel reset | `DISPLAY_RESET_N` | **GPIO 78** |
| Touch | `TOUCH_I2C`, `TOUCH_INT`, `TOUCH_RESET` | as on sheet 4 |

Duke is the WQHD dual-DSI AMOLED (720+720 cmd). Reset/TE on 4VM_08r are GPIO_78 / GPIO_10. Do not invent extra TE GPIOs.

---

## Keys (`page-01.png` sheet 2 + `page-05.png` sheet 6 side-key flex)

Side-key flex (`KEYFLEX` / board 4BZ_03xx) into MSM:

| Key | Net | GPIO |
|---|---|---|
| Camera focus | `FOCUS_KEY` | **GPIO 5** |
| Camera shutter | `SHOT` / `CAMERA_KEY` | **GPIO 4** |
| Power | `POWER_KEY` / `KPDPWR_N` | PMI / PON (not a TLMM camera GPIO) |
| Volume up | `VOL_UP` | keyflex |
| Volume down | `VOL_DOWN` | keyflex |

---

## NFC GPIOs (`page-06.png` / sheet 7) — RM-1104 only

NXP NFC (`N600` class, interconnect `NFC_CTRL`):

| Function | Schematic net | GPIO / clock |
|---|---|---|
| IRQ | `NFC_IRQ` | GPIO **94** |
| FW download / DWL | `NFC_DWL_REQ` | GPIO **30** |
| I2C | `NFC_I2C_SCL` / `NFC_I2C_SDA` | BLSP I2C |
| Clock | `BB_CLK2` | BBCLK2 |

Do **not** take a second-SIM UART or UIM2 pin as NFC. `X2701` on sheet 3 is Dual SIM only.

WOA ACPI names VEN vs DWL vs IRQ differently than some Linux nq-nci properties. Schematic nets for talkman 4VM_08r are the three above plus I2C + BBCLK2.

---

## Qi wireless charge — `WLC_EN` / `WLC_DET` (`page-01.png` + `page-04.png`)

| Net | Where |
|---|---|
| `WLC_EN` | MSM/PMI interconnect `CHARGER_CTRL` → PMI8994 wireless-charge enable |
| `WLC_DET` | Detect into PMI8994 (coil present / charger path) |

Sheet 5 is PMI8994 audio, battery, **wireless charging**, vibra. Qi is enable + detect only on this board. No extra Dual-SIM WLC nets.

---

## TAS IHF I2S (`page-03.png` + `page-04.png`)

Hands-free speaker path:

| Net | Role |
|---|---|
| `IHF_I2S` (`IHF_BCLK` / `IHF_WCLK` / `IHF_DOUT`) | I2S from MSM audio to TAS class-D |
| `IHF_LEFT_EN` | TAS path enable |
| `AUDIO_CTRL` / `AUDIO_OUT` | codec + earpiece / IHF interconnects |

TAS is the IHF amplifier on 4VM_08r, not a WCD IHF pin dump. Speaker is I2S + enable, not analog HPH only.

---

## USB-C — TYPE_C, **no PD sink assumption** (`page-03.png` / sheet 4)

| Block | Schematic |
|---|---|
| Connector | `TYPE_C` / `USB3` SS mux |
| Control | `TYPE_C_CC`, `PD_EN` present as nets |
| VBUS | `USB_VBUS` into PMI |

`PD_EN` and CC exist on the drawing. **Do not assume USB-PD sink/source is implemented or required** for talkman bring-up. Treat the port as USB-C connector + SS mux + VBUS. No Dual-SIM-only USB variant.

---

## Other sheet 2 (`page-01.png`) interconnects (RM-1104)

`SYS_CTRL`, `WLAN`, `NFC_CTRL`, `TYPE_C`, `SD_CARD`, `AUDIO_CTRL`, `CHARGER_CTRL` (`WLC_EN`/`WLC_DET`), `BT`, `WTR`, `NFC`, `FM`, `GPS`, crystal **19.2 MHz**.

---

## Do not copy from Dual SIM / RM-1118

- Second SIM `X2701` / UIM2 (“RM-1118 only” on sheet 3)
- Board **4VM_08d** finder pages (`page-11.png`, `page-12.png`)
- Any “RM-1118 only” callout
- Invented CCI0 rear master, invented PD stack, invented Duke GPIOs other than **TE 10 / RST 78**
