#!/bin/bash
INPUT_NII="$1"

NUM_SLICES=$(fslval "$INPUT_NII" dim3)

if [[ "$NUM_SLICES" -ne 36 ]]; then
  echo "Error: file '$INPUT_NII' does not have 36 slices (dim3 = $NUM_SLICES)."
  exit 1
fi

INPUT_JSON="${INPUT_NII%.nii*}.json"

PHASE_NII="${INPUT_NII/part-mag/part-phase}"
PHASE_JSON="${INPUT_JSON/part-mag/part-phase}"

MAG_NII="${INPUT_NII/part-phase/part-mag}"
MAG_JSON="${INPUT_JSON/part-phase/part-mag}"

# --- Split ---
fslsplit "$INPUT_NII" slice_ -z

# interleave_b --> new part-mag
fslmerge -z interleaved_b \
  slice_0027.nii.gz slice_0018.nii.gz \
  slice_0028.nii.gz slice_0019.nii.gz \
  slice_0029.nii.gz slice_0020.nii.gz \
  slice_0030.nii.gz slice_0021.nii.gz \
  slice_0031.nii.gz slice_0022.nii.gz \
  slice_0032.nii.gz slice_0023.nii.gz \
  slice_0033.nii.gz slice_0024.nii.gz \
  slice_0034.nii.gz slice_0025.nii.gz \
  slice_0035.nii.gz slice_0026.nii.gz

fslcpgeom slice_0019.nii.gz interleaved_b.nii.gz -d
mv interleaved_b.nii.gz "$MAG_NII"

# interleave_a --> new part-phase
fslmerge -z interleaved_a \
  slice_0009.nii.gz slice_0000.nii.gz \
  slice_0010.nii.gz slice_0001.nii.gz \
  slice_0011.nii.gz slice_0002.nii.gz \
  slice_0012.nii.gz slice_0003.nii.gz \
  slice_0013.nii.gz slice_0004.nii.gz \
  slice_0014.nii.gz slice_0005.nii.gz \
  slice_0015.nii.gz slice_0006.nii.gz \
  slice_0016.nii.gz slice_0007.nii.gz \
  slice_0017.nii.gz slice_0008.nii.gz

fslcpgeom slice_0019.nii.gz interleaved_a.nii.gz -d
mv interleaved_a.nii.gz "$PHASE_NII"

# --- JSON ---
if [[ -f "$PHASE_JSON" ]]; then
  cp "$PHASE_JSON" "$MAG_JSON"
fi
cp "$MAG_JSON" "$PHASE_JSON"

rm slice_*.nii.gz
echo "RFMAP repaired"
