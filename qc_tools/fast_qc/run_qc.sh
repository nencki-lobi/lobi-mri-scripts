#!/bin/bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <T1w.nii.gz> <result.json>"
    exit 1
fi

t1=$(realpath "$1")
result=$(realpath "$2")
cd "$(dirname "$0")"

if ! command -v mri_synthseg >/dev/null 2>&1; then
    ml synthseg
fi

if [ ! -x ./niimath ]; then
    curl -fsSLO https://github.com/rordenlab/niimath/releases/latest/download/niimath_lnx.zip
    unzip -q -o niimath_lnx.zip
fi

if [ ! -f ./avg152T1.nii.gz ]; then
    wget -q https://browserqc.org/avg152T1.nii.gz
fi

tmpdir=$(mktemp -d ./tmp.XXXXXX)
seg="$tmpdir/seg.nii.gz"

mri_synthseg \
    --i "$t1" \
    --o "$seg" \
    --fast \
    --cpu \
    --threads 32

./niimath --qc "$t1" \
    --seg "$seg" \
    --csf 4,5,14,15,24,43,44 \
    --wm 2,7,41,46 \
    --air ./avg152T1.nii.gz \
    --json "$result"

rm -rf "$tmpdir"
