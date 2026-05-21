#!/usr/bin/env bash
set -euo pipefail

# Przykład pełnego przebiegu dla jednej sesji:
# 1) analiza dopasowania fieldmap dla wszystkich plików func JSON
# 2) poprawa dopasowań na podstawie mismatch.txt
# 3) preflight dla odpowiadających plików func NIfTI

: > mismatch.txt
for f in sub-*/ses-*/func/sub-*_ses-01_task-alicja1_bold.json; do
  ./analysis_01_fmap_match.sh "$f" >> mismatch.txt
done

./analysis_02_better_fmap_match.sh mismatch.txt

for f in sub-*/ses-*/func/sub-*_ses-01_task-alicja1_bold.nii.gz; do
  ./analysis_03_preflight_fieldmap_check.py \
    --custom-string acq-std \
    --shim \
    --position \
    "$f"
done
