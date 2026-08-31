#!/bin/bash
#
# Check proprietary-files.txt dests against PRODUCT_COPY_FILES in
# vendor/msft/talkman/talkman-{vendor,dsp,ois,camera-xml}.mk.
# Does not rewrite those mks (hand-maintained COPY_FILES + comments).
#
# SPDX-License-Identifier: Apache-2.0

set -euo pipefail

MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi
MY_DIR="$(cd "${MY_DIR}" && pwd)"

ANDROID_ROOT="$(cd "${MY_DIR}/../../.." && pwd)"
VENDOR_MK_DIR="${ANDROID_ROOT}/vendor/msft/talkman"
if [[ ! -d "${VENDOR_MK_DIR}" ]]; then
  VENDOR_MK_DIR="$(cd "${MY_DIR}/../android_vendor_msft_talkman" && pwd)"
fi
LIST="${MY_DIR}/proprietary-files.txt"

if [[ ! -d "${VENDOR_MK_DIR}" ]]; then
  echo "vendor tree missing (tried AOSP vendor/msft/talkman and mirrors/android_vendor_msft_talkman)" >&2
  exit 1
fi

PYTHON=python3
command -v python3 >/dev/null 2>&1 || PYTHON=python
"${PYTHON}" - "${LIST}" "${VENDOR_MK_DIR}" <<'PY'
import pathlib, re, sys

list_path = pathlib.Path(sys.argv[1])
mk_dir = pathlib.Path(sys.argv[2])

listed = []
for line in list_path.read_text(encoding="utf-8").splitlines():
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    listed.append(line.lstrip("/"))

copy_dests = set()
pat = re.compile(
    r":(?:\$\(TARGET_COPY_OUT_(?:VENDOR|SYSTEM|PRODUCT)\)|system|product)/(\S+)"
)
for mk in sorted(mk_dir.glob("talkman-*.mk")):
    text = mk.read_text(encoding="utf-8")
    for raw in text.splitlines():
        s = raw.strip()
        if s.startswith("#"):
            continue
        for m in re.finditer(
            r":(?:\$\(TARGET_COPY_OUT_VENDOR\)|\$\(TARGET_COPY_OUT_SYSTEM\)|\$\(TARGET_COPY_OUT_PRODUCT\)|system|product)/([^ \\\t]+)",
            s,
        ):
            dest = m.group(0)
            dest = dest.lstrip(":")
            dest = dest.replace("$(TARGET_COPY_OUT_VENDOR)/", "vendor/")
            dest = dest.replace("$(TARGET_COPY_OUT_SYSTEM)/", "system/")
            dest = dest.replace("$(TARGET_COPY_OUT_PRODUCT)/", "product/")
            if dest.startswith("system/"):
                pass
            copy_dests.add(dest.rstrip("\\").strip())

listed_set = set(listed)
missing = sorted(copy_dests - listed_set)
extra = sorted(listed_set - copy_dests)
banned = [p for p in listed if re.search(
    r"imx377|ov5693|nanohub|omadm|activity\.napp|fpctzappfingerprint", p, re.I)]

print("COPY_FILES dests:", len(copy_dests))
print("proprietary-files.txt dests:", len(listed_set))
if missing:
    print("in COPY_FILES, missing from list:")
    for p in missing:
        print(" ", p)
if extra:
    print("in list, not in COPY_FILES:")
    for p in extra:
        print(" ", p)
if banned:
    print("banned dests in list:", banned)
    sys.exit(1)
if missing or extra:
    sys.exit(1)
print("proprietary-files.txt matches talkman COPY_FILES dests")
PY
