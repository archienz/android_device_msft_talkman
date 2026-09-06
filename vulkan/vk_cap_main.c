/*
 * talkman-vk-cap — print talkman_vulkan_device_count() from libtalkman-vkcap.
 * Does not invent a physical device. Does not set ro.hwui.use_vulkan.
 */

#include <stdio.h>

#include "VkCap.h"

int main(void)
{
    printf("%d\n", talkman_vulkan_device_count());
    return 0;
}
