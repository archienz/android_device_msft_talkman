#!/bin/bash
#
# Copy proprietary blobs listed in proprietary-files.txt from a dump (or adb)
# into vendor/msft/talkman/proprietary. Destinations match PRODUCT_COPY_FILES.
#
# Usage:
#   ./extract-files.sh /path/to/dump
#   ./extract-files.sh                 # adb pull
#
# Dump layout: system/, vendor/, product/ as on-device (or AOSP out).
# Refuses imx377 / ov5693 / nanohub / OMADM dests even if the dump has them.
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

DEVICE=talkman
VENDOR=msft

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi
MY_DIR="$(cd "${MY_DIR}" && pwd)"

ANDROID_ROOT="$(cd "${MY_DIR}/../../.." && pwd)"
OUT_BASE="${ANDROID_ROOT}/vendor/${VENDOR}/${DEVICE}/proprietary"
if [[ ! -d "$(dirname "${OUT_BASE}")" ]]; then
  OUT_BASE="$(cd "${MY_DIR}/../android_vendor_msft_talkman" && pwd)/proprietary"
fi
LIST="${MY_DIR}/proprietary-files.txt"

SRC="${1:-}"

BANNED='imx377|ov5693|nanohub|activity\.napp|double_twist\.napp|pickup_gesture\.napp|sig_motion\.napp|napp_list\.cfg|fpctzappfingerprint|fingerprint\.bullhead|lib_fpc_tac_shared|context_hub\.default|omadm|OMADM|DCMO|DMConfigUpdate|com\.android\.omadm|whitelist_com\.android\.omadm'

if [[ ! -f "${LIST}" ]]; then
  echo "missing ${LIST}" >&2
  exit 1
fi

mkdir -p "${OUT_BASE}"

copy_one() {
  local dest="$1"
  dest="${dest#/}"
  if echo "${dest}" | grep -Eqi "${BANNED}"; then
    echo "skip banned dest ${dest}" >&2
    return 0
  fi

  local src_file=""
  if [[ -n "${SRC}" ]]; then
    if [[ -f "${SRC}/${dest}" ]]; then
      src_file="${SRC}/${dest}"
    elif [[ -f "${SRC}/system/${dest}" ]]; then
      src_file="${SRC}/system/${dest}"
    elif [[ "${dest}" == vendor/* && -f "${SRC}/${dest}" ]]; then
      src_file="${SRC}/${dest}"
    elif [[ "${dest}" == vendor/* && -f "${SRC}/system/${dest}" ]]; then
      src_file="${SRC}/system/${dest}"
    else
      echo "missing in dump: ${dest}" >&2
      return 1
    fi
  else
    local tmp
    tmp="$(mktemp)"
    if ! adb pull "/${dest}" "${tmp}" >/dev/null 2>&1; then
      if ! adb pull "/system/${dest}" "${tmp}" >/dev/null 2>&1; then
        rm -f "${tmp}"
        echo "missing on device: ${dest}" >&2
        return 1
      fi
    fi
    src_file="${tmp}"
  fi

  # Map installed dest -> vendor tree path used by talkman-*.mk.
  local out="${OUT_BASE}/${dest}"
  case "${dest}" in
    vendor/etc/camera/*)
      out="${OUT_BASE}/etc/camera/${dest#vendor/etc/camera/}"
      ;;
    system/etc/camera/*)
      out="${OUT_BASE}/etc/camera/${dest#system/etc/camera/}"
      ;;
    vendor/*) out="${OUT_BASE}/${dest}" ;;
    product/*) out="${OUT_BASE}/${dest}" ;;
    system/etc/*) out="${OUT_BASE}/etc/${dest#system/etc/}" ;;
    system/lib/*) out="${OUT_BASE}/lib/${dest#system/lib/}" ;;
    system/lib64/*) out="${OUT_BASE}/lib64/${dest#system/lib64/}" ;;
  esac
  # Daemons listed as vendor/bin in the extract list are installed from
  # proprietary/bin (not proprietary/vendor/bin) in talkman-vendor.mk.
  case "${dest}" in
    vendor/bin/ATFWD-daemon|vendor/bin/btnvtool|vendor/bin/cnd|vendor/bin/cnss-daemon|vendor/bin/ims_rtp_daemon|vendor/bin/imsdatadaemon|vendor/bin/imsqmidaemon|vendor/bin/irsc_util|vendor/bin/loc_launcher|vendor/bin/location-mq|vendor/bin/lowi-server|vendor/bin/msm_irqbalance|vendor/bin/thermal-engine|vendor/bin/netmgrd|vendor/bin/nl_listener|vendor/bin/pm-proxy|vendor/bin/pm-service|vendor/bin/qmakernote-xtract|vendor/bin/qmuxd|vendor/bin/rmt_storage|vendor/bin/subsystem_ramdump)
      out="${OUT_BASE}/bin/${dest#vendor/bin/}"
      ;;
  esac

  mkdir -p "$(dirname "${out}")"
  cp -f "${src_file}" "${out}"
  if [[ -z "${SRC}" ]]; then
    rm -f "${src_file}"
  fi
  echo "extracted ${dest} -> ${out}"
}

fail=0
while IFS= read -r line || [[ -n "${line}" ]]; do
  line="${line%%$'\r'}"
  case "${line}" in
    ''|\#*) continue ;;
  esac
  if ! copy_one "${line}"; then
    fail=1
  fi
done < "${LIST}"

if [[ "${fail}" -ne 0 ]]; then
  echo "extract-files.sh: some blobs were missing (real dump required, no sim)." >&2
  exit 1
fi

"${MY_DIR}/setup-makefiles.sh"
