/*
 * Talkman sensor inventory. Not nanohub, not LGE, not FPC, not context hub.
 *
 * Runtime HAL is sensors/sensors_hal.c (module sensors.talkman). This list
 * matches that HAL. Do not add BMI160 / BMM150 / BMP280 / RPR0521, nanohub
 * gestures (twist/tap/tilt/pickup/sync), or fusion types — those chips and
 * the hub firmware are not on this phone. SensorService fuses
 * gravity / linear accel / rotation vector from accel+gyro+mag.
 *
 * WOA ACPI (8992 DSDT/SSDT):
 *   SEN1  QCOM2495   Windows ADSP path; Linux is AP I2C
 *   APS1  MSHW1016   QPDS-T900 @ I2C7 0x39, IRQ GPIO 40
 *   HALL  MSHW1015   GPIO 42 / 75
 *   BLSP1 QUP5       ICM-20648 0x68, AK09912 0x0c, ZPA2326 0x5c
 *
 * SIAD MSHW100F @ 0x2c is UNKNOWN — not published.
 */

#include <hardware/sensors.h>
#include <stddef.h>

const int kVersion = 1;

enum {
    HANDLE_MAG = 1,
    HANDLE_PROX = 2,
    HANDLE_LIGHT = 3,
    HANDLE_PRESS = 4,
    HANDLE_HALL_FRONT = 5,
    HANDLE_HALL_BACK = 6,
    HANDLE_ACCEL = 7,
    HANDLE_GYRO = 8,
    HANDLE_TEMP = 9,
};

const sensor_t kSensorList[] = {
    {
        "AK09912 Magnetometer",
        "Asahi Kasei",
        kVersion,
        HANDLE_MAG,
        SENSOR_TYPE_MAGNETIC_FIELD,
        4900.0f,
        0.15f,
        1.1f,
        10000,
        0,
        0,
        SENSOR_STRING_TYPE_MAGNETIC_FIELD,
        "",
        200000,
        SENSOR_FLAG_CONTINUOUS_MODE,
        { NULL, NULL }
    },
    {
        "QPDS-T900 Proximity",
        "Avago",
        kVersion,
        HANDLE_PROX,
        SENSOR_TYPE_PROXIMITY,
        5.0f,
        5.0f,
        0.2f,
        0,
        0,
        0,
        SENSOR_STRING_TYPE_PROXIMITY,
        "",
        0,
        SENSOR_FLAG_ON_CHANGE_MODE | SENSOR_FLAG_WAKE_UP,
        { NULL, NULL }
    },
    {
        "QPDS-T900 Light",
        "Avago",
        kVersion,
        HANDLE_LIGHT,
        SENSOR_TYPE_LIGHT,
        60000.0f,
        1.0f,
        0.2f,
        0,
        0,
        0,
        SENSOR_STRING_TYPE_LIGHT,
        "",
        0,
        SENSOR_FLAG_ON_CHANGE_MODE,
        { NULL, NULL }
    },
    {
        "ZPA2326 Pressure",
        "Murata",
        kVersion,
        HANDLE_PRESS,
        SENSOR_TYPE_PRESSURE,
        1100.0f,
        0.0015625f,
        0.1f,
        200000,
        0,
        0,
        SENSOR_STRING_TYPE_PRESSURE,
        "",
        1000000,
        SENSOR_FLAG_CONTINUOUS_MODE,
        { NULL, NULL }
    },
    {
        "Hall front / lid",
        "GPIO",
        kVersion,
        HANDLE_HALL_FRONT,
        SENSOR_TYPE_ORIENTATION,
        360.0f,
        180.0f,
        0.001f,
        0,
        0,
        0,
        SENSOR_STRING_TYPE_ORIENTATION,
        "",
        0,
        SENSOR_FLAG_ON_CHANGE_MODE,
        { NULL, NULL }
    },
    {
        "Hall back cover",
        "GPIO",
        kVersion,
        HANDLE_HALL_BACK,
        SENSOR_TYPE_ORIENTATION,
        360.0f,
        180.0f,
        0.001f,
        0,
        0,
        0,
        SENSOR_STRING_TYPE_ORIENTATION,
        "",
        0,
        SENSOR_FLAG_ON_CHANGE_MODE,
        { NULL, NULL }
    },
    {
        "ZPA2326 Temperature",
        "Murata",
        kVersion,
        HANDLE_TEMP,
        SENSOR_TYPE_AMBIENT_TEMPERATURE,
        85.0f,
        0.00649f,
        0.1f,
        200000,
        0,
        0,
        SENSOR_STRING_TYPE_AMBIENT_TEMPERATURE,
        "",
        1000000,
        SENSOR_FLAG_CONTINUOUS_MODE,
        { NULL, NULL }
    },
    {
        "ICM-206xx Accelerometer",
        "TDK InvenSense",
        kVersion,
        HANDLE_ACCEL,
        SENSOR_TYPE_ACCELEROMETER,
        39.2266f,
        0.0012f,
        0.5f,
        5000,
        0,
        0,
        SENSOR_STRING_TYPE_ACCELEROMETER,
        "",
        200000,
        SENSOR_FLAG_CONTINUOUS_MODE,
        { NULL, NULL }
    },
    {
        "ICM-206xx Gyroscope",
        "TDK InvenSense",
        kVersion,
        HANDLE_GYRO,
        SENSOR_TYPE_GYROSCOPE,
        34.9066f,
        0.001f,
        0.5f,
        5000,
        0,
        0,
        SENSOR_STRING_TYPE_GYROSCOPE,
        "",
        200000,
        SENSOR_FLAG_CONTINUOUS_MODE,
        { NULL, NULL }
    },
};

const size_t kSensorCount = sizeof(kSensorList) / sizeof(sensor_t);
