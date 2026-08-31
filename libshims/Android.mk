# Copyright 2010 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

LOCAL_PATH := $(call my-dir)

# Leftover unused bullhead Make shims are gone:
#   libaudioclient_shim (AudioSystem::setErrorCallback) — no talkman audio blob
#   slim_shim empty SensorEventQueue stubs — never-sim; slim_daemon uses NDK SAP
# Camera (QCamera2) and GNSS HIDL are rebuilt in-tree — no camera/gps .so shims.
# Real shim is Soong libcutils/Android.bp (strdup16to8 / strdup8to16).
