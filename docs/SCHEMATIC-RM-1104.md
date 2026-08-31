# Lumia 950 schematic notes — RM-1104 only

Source: Microsoft service schematic
`Lumia 950 RM-1104 / Lumia 950 Dual SIM RM-1118`, v1.0, 16.10.2015.

PDF: `docs/hardware/Lumia950-RM-1104-RM-1118-schematic.pdf`

**This port is single-SIM talkman.** Use board **4VM_08r** (RM-1104).

Do **not** use Dual SIM RM-1118 / board **4VM_08d**. Page 2 marks `X2701` UIM2 as “Lumia XXX Dual SIM, RM-1118 only”. Pages 12–13 are the Dual SIM component finder.

## Board vs SKU

| SKU | Board | Use |
|---|---|---|
| RM-1104 talkman | 4VM_08r | **Yes** |
| RM-1118 Dual SIM | 4VM_08d | **No** |

## Camera (page 2) vs our DT

| Net | Schematic | Our tree before this note |
|---|---|---|
| Rear CSI | CSI0 4-lane + clk | `csiphy/csid` index 0, lane `0x4320` |
| Rear MCLK | `CAM_MCLK0` (MSM T1) | GPIO 13 / mclk0 |
| Rear I2C | **CCI1** (`CCI1_I2C_CLK` / `CCI1_I2C_DATA`) | was `qcom,cci-master = <0>` |
| Front (Ducati) | CSI2, `CAM_MCLK2`, `CAM_FRONT_RES_N` GPIO 104 | CSI2, GPIO 15 / 104 |
| Iris (SIIRI) | CSI2 extra lanes, **CCI0**, `IRIS_CAM_RES_N` GPIO 102, `CAM_MCLK1` GPIO 14 | not a QCamera CameraId |
| Torch | `TORCH_EN` GPIO 12 | GPIO 12 |
| Rails | LVS1 1.8 V, L25 1.1 V, L23 2.8 V, L29 2.8 V | LVS1 always-on; L25/L23/L29 sequenced |

Rear **CCI master 1** matches the drawing and EpicLPer lab ident. That is a schematic fact, not an invented slave-id. 7-bit SID is still not on this PDF.

## Other P0-related nets (RM-1104)

| Function | Schematic |
|---|---|
| Qi | `WLC_EN`, `WLC_DET` into PMI8994 |
| NFC | I2C + `NFC_IRQ` GPIO 94, `NFC_DWL_REQ` GPIO 30, `BB_CLK2` |
| Speaker | IHF I2S + `IHF_LEFT_EN` (TAS path) |
| USB-C | TYPE_C block, `PD_EN`, SS mux, no assumption of USB-PD sink |
| Keys | FOCUS GPIO 5, SHOT GPIO 4, POWER, VOL |

## Do not copy from Dual SIM pages

- Second SIM `X2701` / UIM2
- Board 4VM_08d finder pages
- Any “RM-1118 only” callout
