#ifndef TALKMAN_VKCAP_H
#define TALKMAN_VKCAP_H

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Real ICD + loader count for talkman (MSM8992 / Adreno 418).
 * Returns 0 if vulkan.msm8992.so is missing or vkEnumeratePhysicalDevices
 * reports 0. Does not invent a physical device.
 */
int talkman_vulkan_device_count(void);

#ifdef __cplusplus
}
#endif

#endif /* TALKMAN_VKCAP_H */
