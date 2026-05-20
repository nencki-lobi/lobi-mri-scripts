#!/usr/bin/env python3
import argparse
import json
import re
import sys
from pathlib import Path


def load_json(path):
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def intended_list(value):
    # Accept the two common IntendedFor shapes we actually want to support.
    if isinstance(value, str):
        return [value]
    if isinstance(value, list) and all(isinstance(x, str) for x in value):
        return value
    return None


def first_match(fmap_dir, subject_id, session_id, custom_string, direction):
    # Match fieldmaps by subject/session, direction and optional label fragment.
    pat = f"{subject_id}_{session_id}*"
    cand = []
    for p in sorted(fmap_dir.glob(f"{pat}_dir-{direction}*_epi.json")):
        if custom_string and custom_string not in p.name:
            continue
        cand.append(p)
    return cand[0] if cand else None


def main():
    ap = argparse.ArgumentParser(add_help=True)
    ap.add_argument("--custom-string", default="acq-std")
    ap.add_argument("--shim", action="store_true")
    ap.add_argument("--position", action="store_true")
    ap.add_argument("func")
    args = ap.parse_args()

    func = Path(args.func)
    try:
        func_abs = func.resolve()
    except FileNotFoundError:
        print(func, file=sys.stdout)
        return 1

    if not func.is_file() or not str(func).endswith(".nii.gz"):
        print(func_abs, file=sys.stdout)
        return 1

    ses_dir = func.parent.parent
    fmap_dir = ses_dir / "fmap"
    if not fmap_dir.is_dir():
        print(func_abs, file=sys.stdout)
        return 1

    subject_id = func.name.split("_ses-")[0]
    session_id = func.parent.parent.name
    expected = f"{session_id}/func/{func.name}"

    # Both AP and PA must exist and both must point to this exact func run.
    ap_json = first_match(fmap_dir, subject_id, session_id, args.custom_string, "AP")
    pa_json = first_match(fmap_dir, subject_id, session_id, args.custom_string, "PA")
    if not ap_json or not pa_json:
        print(func_abs, file=sys.stdout)
        return 1

    try:
        func_meta = None
        if args.shim or args.position:
            func_json = func.with_suffix("").with_suffix(".json")
            if not func_json.is_file():
                raise ValueError
            func_meta = load_json(func_json)

        for fmap_json in (ap_json, pa_json):
            meta = load_json(fmap_json)
            intended = intended_list(meta.get("IntendedFor"))
            if not intended or expected not in intended:
                raise ValueError
            # Keep IntendedFor strict enough to catch malformed paths early.
            for item in intended:
                if not re.match(r"^ses-[^/]+/(func|dwi)/sub-[^/]+_ses-[^/]+_.*_(bold|dwi)\.nii\.gz$", item):
                    raise ValueError

            # Optional checks compare the run metadata against each fieldmap.
            if args.shim and func_meta.get("ShimSetting") != meta.get("ShimSetting"):
                raise ValueError
            if args.position and func_meta.get("ImageOrientationPatientDICOM") != meta.get(
                "ImageOrientationPatientDICOM"
            ):
                raise ValueError
    except Exception:
        print(func_abs, file=sys.stdout)
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
