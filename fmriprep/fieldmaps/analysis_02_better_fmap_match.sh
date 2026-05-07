#!/usr/bin/env bash
set -euo pipefail

find_better_match() {
    local fmri_json="$1"

    python3 - "$fmri_json" <<'PY'
import json
import math
import os
import sys
from glob import glob

fmri_path = sys.argv[1]

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def floats_close(a, b, tol=1e-6):
    return len(a) == len(b) and all(math.isclose(x, y, abs_tol=tol) for x, y in zip(a, b))

fmri = load_json(fmri_path)
fmri_orient = fmri.get("ImageOrientationPatientDICOM", [])
fmri_shim = fmri.get("ShimSetting", [])
ses_dir = os.path.dirname(os.path.dirname(fmri_path))
fmap_dir = os.path.join(ses_dir, "fmap")

ap_candidates = []
pa_candidates = []

for fmap_path in sorted(glob(os.path.join(fmap_dir, "*_epi.json"))):
    base = os.path.basename(fmap_path)
    if "_dir-AP" not in base and "_dir-PA" not in base:
        continue

    fmap = load_json(fmap_path)
    fmap_orient = fmap.get("ImageOrientationPatientDICOM", [])
    fmap_shim = fmap.get("ShimSetting", [])

    orient_match = floats_close(fmri_orient, fmap_orient)
    shim_match = fmri_shim == fmap_shim

    if orient_match and shim_match:
        item = (base, os.path.abspath(fmap_path))
        if "_dir-AP" in base:
            ap_candidates.append(item)
        if "_dir-PA" in base:
            pa_candidates.append(item)

ap_candidates.sort(key=lambda x: x[0])
pa_candidates.sort(key=lambda x: x[0])

ap_match = ap_candidates[0][1] if ap_candidates else ""
pa_match = pa_candidates[0][1] if pa_candidates else ""

print(f"{os.path.abspath(fmri_path)}\t{ap_match}\t{pa_match}")
PY
}

main() {
    local list_file="${1:-mismatch.txt}"

    : > better_match.tsv

    while IFS= read -r fmri_json; do
        [[ -z "$fmri_json" ]] && continue
        find_better_match "$fmri_json" | tee -a better_match.tsv
    done < "$list_file"
}

main "$@"
