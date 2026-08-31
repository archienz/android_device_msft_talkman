/*
 * Copyright (C) 2015 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef _BDROID_BUILDCFG_H
#define _BDROID_BUILDCFG_H

/* MAC is not here. libbt-vendor:
 *  1. /persist/bdaddr.txt (ro.bt.bdaddr_path; installer DPP/QCOM/BT.PROVISION)
 *  2. QCA OTP when persist is missing (talkman nvm_tlv_3.2.bin / btnv32.bin
 *     NVM tag 2 is zeros; QCOM_BT_READ_ADDR_FROM_PROP analog of g_use_otpmac=1)
 * Do not put CAF/bullhead sample BD_ADDR (77:78:23:01:56:22) here.
 */

#define BLE_VND_INCLUDED TRUE
#define BTA_DISABLE_DELAY 1000 /* in milliseconds */

#define BT_CLEAN_TURN_ON_DISABLED 1
#endif
