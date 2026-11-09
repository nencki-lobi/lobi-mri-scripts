#!/bin/bash
set -euo pipefail

seed="$1"
bold="$2"
fwhm="$3"

out_dir="$(dirname "$bold")"
prefix="$out_dir/seed_to_voxel_${fwhm}mm"

if [[ "$fwhm" != "0" ]]; then
    3dmerge \
        -1blur_fwhm "$fwhm" \
        -doall \
        -prefix "${prefix}_bold.nii.gz" \
        "$bold"

    bold="${prefix}_bold.nii.gz"
fi

3dTcorr1D \
    -pearson \
    -prefix "${prefix}_r.nii.gz" \
    "$bold" \
    "$seed"

3dTcorr1D \
    -pearson \
    -Fisher \
    -prefix "${prefix}_z.nii.gz" \
    "$bold" \
    "$seed"

echo "Zapisano mapy: ${prefix}_r.nii.gz i ${prefix}_z.nii.gz"