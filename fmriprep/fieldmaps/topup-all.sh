#!/usr/bin/env bash
set -euo pipefail

SUB="${1:?usage: topup-all.sh sub-01 ses-01 /path/to/bids}"
SES="${2:?usage: topup-all.sh sub-01 ses-01 /path/to/bids}"
BIDS="$(realpath "${3:?usage: topup-all.sh sub-01 ses-01 /path/to/bids}")"

# Neurodesk modules are not guaranteed to be loaded in non-interactive shells.
if ! command -v module >/dev/null 2>&1; then
  # shellcheck disable=SC1091
  source /usr/share/lmod/lmod/init/bash
fi

FMAP_DIR="${BIDS}/${SUB}/${SES}/fmap"
FUNC_DIR="${BIDS}/${SUB}/${SES}/func"
WORK_BASE="$(mktemp -d "${FMAP_DIR}/.topup_mean_work.XXXXXX")"
LEGACY_WORK_DIR="${FMAP_DIR}/topup_mean_work"

cleanup() {
  local status=$?
  rm -rf "$WORK_BASE"
  rm -rf "$LEGACY_WORK_DIR"
}
trap cleanup EXIT

if [ ! -d "$FMAP_DIR" ]; then
  echo "ERROR: missing fmap directory: $FMAP_DIR" >&2
  exit 1
fi
if [ ! -d "$FUNC_DIR" ]; then
  echo "ERROR: missing func directory: $FUNC_DIR" >&2
  exit 1
fi

shopt -s nullglob
AP_FILES=( "${FMAP_DIR}/${SUB}_${SES}_acq-std_dir-AP_run-"*_epi.nii.gz )
PA_FILES=( "${FMAP_DIR}/${SUB}_${SES}_acq-std_dir-PA_run-"*_epi.nii.gz )

if [ "${#AP_FILES[@]}" -eq 0 ] || [ "${#PA_FILES[@]}" -eq 0 ]; then
  echo "ERROR: nie znalazlem AP/PA epi w ${FMAP_DIR}" >&2
  exit 1
fi

image_shape() {
  python3 - "$1" <<'PY'
import sys

import nibabel as nib

img = nib.load(sys.argv[1])
print("x".join(str(v) for v in img.shape[:3]))
PY
}

read_total_readout_time() {
  local json_path="$1"
  local trt
  trt=$(awk -F: '/"TotalReadoutTime"/ {gsub(/[ ,]/, "", $2); print $2; exit}' "$json_path")
  if [ -z "$trt" ]; then
    echo "ERROR: brak TotalReadoutTime w $json_path" >&2
    exit 1
  fi
  printf '%s\n' "$trt"
}

write_json_sidecars() {
  local fieldmap_json="$1"
  local magnitude_json="$2"
  local sub="$3"
  local ses="$4"
  shift 4
  local -a intended=( "$@" )
  local i sep

  {
    printf '{\n'
    printf '  "Units": "Hz",\n'
    printf '  "B0FieldIdentifier": "mean_topup_%s_%s",\n' "$sub" "$ses"
    printf '  "IntendedFor": [\n'
    for i in "${!intended[@]}"; do
      sep=','
      if [ "$i" -eq "$((${#intended[@]} - 1))" ]; then
        sep=''
      fi
      printf '    "%s"%s\n' "${intended[$i]}" "$sep"
    done
    printf '  ]\n'
    printf '}\n'
  } > "$fieldmap_json"

  printf '{}\n' > "$magnitude_json"
}

declare -A SHAPE_COUNTS=()
declare -A FILE_SHAPES=()
ALL_FMAPS=( "${AP_FILES[@]}" "${PA_FILES[@]}" )
for img in "${ALL_FMAPS[@]}"; do
  shape=$(image_shape "$img")
  FILE_SHAPES["$img"]="$shape"
  SHAPE_COUNTS["$shape"]=$(( ${SHAPE_COUNTS["$shape"]:-0} + 1 ))
done

BEST_SHAPE=""
BEST_COUNT=0
for shape in "${!SHAPE_COUNTS[@]}"; do
  count=${SHAPE_COUNTS["$shape"]}
  if [ "$count" -gt "$BEST_COUNT" ]; then
    BEST_SHAPE="$shape"
    BEST_COUNT="$count"
  fi
done

IMAGES=()
SKIPPED=()
for img in "${ALL_FMAPS[@]}"; do
  if [ "${FILE_SHAPES[$img]}" = "$BEST_SHAPE" ]; then
    IMAGES+=("$img")
  else
    SKIPPED+=("$img")
  fi
done

if [ "${#SKIPPED[@]}" -gt 0 ]; then
  echo "WARNING: skipping ${#SKIPPED[@]} fieldmap(s) with mismatched shape; using common shape ${BEST_SHAPE}" >&2
  for img in "${SKIPPED[@]}"; do
    echo "  $img" >&2
  done
fi

if [ "${#IMAGES[@]}" -lt 2 ]; then
  echo "ERROR: fewer than 2 compatible fieldmaps remain after shape filtering" >&2
  exit 1
fi

echo "Writing JSON sidecars..."
mapfile -t INTENDED < <(find "$FUNC_DIR" -maxdepth 1 -type f -name "${SUB}_${SES}_*_bold.nii.gz" | sort | sed "s#^${BIDS}/${SUB}/##")

write_json_sidecars \
  "${FMAP_DIR}/${SUB}_${SES}_acq-mean_fieldmap.json" \
  "${FMAP_DIR}/${SUB}_${SES}_acq-mean_magnitude.json" \
  "$SUB" \
  "$SES" \
  "${INTENDED[@]}"

module load fsl/6.0.7.22
FSL_BIN_DIR="/home/jovyan/shared_storage/fsl/bin"

WORK="$(mktemp -d "${WORK_BASE}/topup.XXXXXX")"
ACQPARAMS="${WORK}/acqparams.txt"
TOPUP_INPUT="${WORK}/topup_input.nii.gz"
TOPUP_BASE="${WORK}/topup"
TOPUP_UNWARPED="${WORK}/topup_unwarped.nii.gz"
FIELDMAP_NII="${FMAP_DIR}/${SUB}_${SES}_acq-mean_fieldmap.nii.gz"
MAGNITUDE_NII="${FMAP_DIR}/${SUB}_${SES}_acq-mean_magnitude.nii.gz"

REF="${IMAGES[0]}"
HARMONIZED=()
for img in "${IMAGES[@]}"; do
  copy="${WORK}/$(basename "$img")"
  cp "$img" "$copy"
  if [ "$img" != "$REF" ]; then
    "$FSL_BIN_DIR/fslcpgeom" "$REF" "$copy"
  fi
  HARMONIZED+=( "$copy" )
done

: > "$ACQPARAMS"
for img in "${IMAGES[@]}"; do
  json="${img%.nii.gz}.json"
  trt="$(read_total_readout_time "$json")"
  case "$img" in
    *"_dir-AP_"*) echo "0 -1 0 $trt" >> "$ACQPARAMS" ;;
    *"_dir-PA_"*) echo "0 1 0 $trt" >> "$ACQPARAMS" ;;
    *) echo "ERROR: unknown PE direction in $img" >&2; exit 1 ;;
  esac
done

echo "Merging ${#HARMONIZED[@]} EPI fieldmap images..."
"$FSL_BIN_DIR/fslmerge" -t "$TOPUP_INPUT" "${HARMONIZED[@]}"

echo "Running TOPUP..."
"$FSL_BIN_DIR/topup" \
  --imain="$TOPUP_INPUT" \
  --datain="$ACQPARAMS" \
  --config=b02b0.cnf \
  --out="$TOPUP_BASE" \
  --iout="$TOPUP_UNWARPED" \
  --fout="$FIELDMAP_NII"

echo "Creating magnitude reference..."
"$FSL_BIN_DIR/fslmaths" "$TOPUP_UNWARPED" -Tmean "$MAGNITUDE_NII"

rm -rf "$WORK"

echo "Done:"
echo "  $FIELDMAP_NII"
echo "  ${FMAP_DIR}/${SUB}_${SES}_acq-mean_fieldmap.json"
echo "  $MAGNITUDE_NII"
echo "  ${FMAP_DIR}/${SUB}_${SES}_acq-mean_magnitude.json"
