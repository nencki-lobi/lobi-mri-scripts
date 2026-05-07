#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "usage: $0 <fmri_json>" >&2
    exit 1
fi

fmri_json="$1"

func_dir="$(dirname "$fmri_json")"
ses_dir="$(dirname "$func_dir")"
fmap_dir="$ses_dir/fmap"

fmri_base="$(basename "$fmri_json")"
subject_id="${fmri_base%%_ses-*}"
rest_after_subject="${fmri_base#${subject_id}_}"
session_id="${rest_after_subject%%_task-*}"

ap_json="$fmap_dir/${subject_id}_${session_id}_acq-std_dir-AP_epi.json"
pa_json="$fmap_dir/${subject_id}_${session_id}_acq-std_dir-PA_epi.json"

if [[ ! -f "$ap_json" || ! -f "$pa_json" ]]; then
    echo "$(realpath "$fmri_json")"
    exit 0
fi

python3 - "$fmri_json" "$ap_json" "$pa_json" <<'PY'
import json
import math
import os
import sys

fmri_path, ap_path, pa_path = sys.argv[1:4]

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def floats_close(a, b, tol=1e-6):
    return len(a) == len(b) and all(math.isclose(x, y, abs_tol=tol) for x, y in zip(a, b))

fmri = load_json(fmri_path)
ap = load_json(ap_path)
pa = load_json(pa_path)

fmri_orient = fmri["ImageOrientationPatientDICOM"]
fmri_shim = fmri["ShimSetting"]
ap_orient = ap["ImageOrientationPatientDICOM"]
pa_orient = pa["ImageOrientationPatientDICOM"]
ap_shim = ap["ShimSetting"]
pa_shim = pa["ShimSetting"]

orient_matches = floats_close(fmri_orient, ap_orient) and floats_close(fmri_orient, pa_orient)
shim_matches = (fmri_shim == ap_shim) or (fmri_shim == pa_shim)

if not (orient_matches and shim_matches):
    print(os.path.abspath(fmri_path))
PY
