/* Copyright (c) 2015, The Linux Foundataion. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *     * Neither the name of The Linux Foundation nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR IMPLIED
 * WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT
 * ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#ifndef __QCAMERA_FLASH_H__
#define __QCAMERA_FLASH_H__

#include <hardware/camera_common.h>

extern "C" {
#include <mm_camera_interface.h>
}

namespace qcamera {

#define QCAMERA_TORCH_CURRENT_VALUE 200

/* Talkman (Lumia 950 RM-1104, board 4VM_08r) has no msm_flash subdev.
 * mm-camera-daemon only knows about /dev/video flash subdevs, so
 * cam_capability_t::flash_available comes back 0 and flash_dev_name is empty.
 * The LED is real, so QCameraFlash drives the LED class device instead.
 *
 * Schematic sheet 3 (page-02), verified from the PDF text layer by pin ball
 * rather than from OCR: the flash is driver N1400, VIN on VPH_PWR, three
 * 0u47H inductors (L1400..L1402) on SW1..SW3 and outputs VOUT1..VOUT5 feeding
 * LEDR/LEDG/LEDB -- the triple-LED "natural flash". Its control pins are
 *
 *   B1 STROBE  <- FSTROBE
 *   B3 TORCH   <- TORCH_EN, MSM ball BH5 = GPIO 12
 *   A3 ENABLE  <- no net label on the sheet
 *   B2 TXMASK
 *   A1/A2 SDA/SCL <- CCI0_I2C (GPIO 17 / GPIO 18)
 *
 * So GPIO 12 is one hardware trigger into an I2C-programmed driver, which is
 * why torch.dtsi binds it with leds-gpio and not qpnp-flash-led. Two things
 * follow. Torch current levels live in N1400 registers, so if the GPIO
 * toggles and nothing lights up, the driver needs I2C setup -- and that needs
 * the part number and 7-bit address, neither of which is printed on the sheet.
 * And a single enable line cannot be sequenced into a metered
 * pre-flash/main-flash strobe, which the daemon owns anyway, so nothing here
 * advertises AE flash modes.
 */
#define QCAMERA_GPIO_TORCH_NODE "/sys/class/leds/led:flash_torch"

/* msm8992_camera.xml declares CameraId 0 only, the rear IMX230 on CCI1.
 * TORCH_EN belongs to that sensor; the front (CSI2, GPIO 104) and the iris
 * camera have no flash net on the drawing.
 */
#define QCAMERA_GPIO_TORCH_CAMERA_ID 0

class QCameraFlash {
public:
    static QCameraFlash& getInstance();

    /* True when camera_id owns the leds-gpio torch and the class device is
     * actually present. Used to report ANDROID_FLASH_INFO_AVAILABLE, which is
     * what gates ICameraDevice::setTorchMode in the framework.
     */
    static bool hasGpioTorch(const int camera_id);

    int32_t registerCallbacks(const camera_module_callbacks_t* callbacks);
    int32_t initFlash(const int camera_id);
    int32_t setFlashMode(const int camera_id, const bool on);
    int32_t deinitFlash(const int camera_id);
    int32_t reserveFlashForCamera(const int camera_id);
    int32_t releaseFlashFromCamera(const int camera_id);

private:
    QCameraFlash();
    virtual ~QCameraFlash();
    QCameraFlash(const QCameraFlash&);
    QCameraFlash& operator=(const QCameraFlash&);

    int32_t setGpioTorchMode(const bool on);

    const camera_module_callbacks_t *m_callbacks;
    int32_t m_flashFds[MM_CAMERA_MAX_NUM_SENSORS];
    bool m_flashOn[MM_CAMERA_MAX_NUM_SENSORS];
    bool m_cameraOpen[MM_CAMERA_MAX_NUM_SENSORS];
    /* Set by initFlash when the camera has no flash subdev but does have the
     * leds-gpio torch, so setFlashMode/deinitFlash pick the sysfs path.
     */
    bool m_gpioTorch[MM_CAMERA_MAX_NUM_SENSORS];
};

}; // namespace qcamera

#endif /* __QCAMERA_FLASH_H__ */
