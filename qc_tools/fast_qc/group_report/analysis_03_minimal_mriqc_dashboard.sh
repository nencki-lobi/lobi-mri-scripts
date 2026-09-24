#!/bin/bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage:
  bash src/analysis_03_minimal_mriqc_dashboard.sh [QC_JSON_DIR] [OUTPUT_DIR]

Arguments:
  QC_JSON_DIR  Directory containing sub-*.json QC metric files. Default: results
  OUTPUT_DIR   Directory for group outputs. Default: QC_JSON_DIR

Outputs:
  group.tsv
  group_boxplots.html
  group_umap_tsne.tsv
  group_umap_tsne.html
  group_umap_tsne.png
  group_dashboard.html
  group_dashboard_summary.json
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

if [ "$#" -gt 2 ]; then
    usage >&2
    exit 2
fi

PROJECT_DIR="${PROJECT_DIR:-$PWD}"
cd "${PROJECT_DIR}"

INPUT_DIR="${1:-${INPUT_DIR:-results}}"
OUTPUT_DIR="${2:-${OUTPUT_DIR:-${INPUT_DIR}}}"
CONTAINER_SCRIPT="${PROJECT_DIR}/src/analysis_03_mriqc_dashboard_container.py"
MRIQC_IMAGE="/cvmfs/neurodesk.ardc.edu.au/containers/mriqc_24.0.2_20241108/mriqc_24.0.2_20241108.simg"

if [ ! -d "${INPUT_DIR}" ]; then
    echo "QC JSON directory not found: ${INPUT_DIR}" >&2
    exit 1
fi
if [ ! -f "${CONTAINER_SCRIPT}" ]; then
    echo "Container Python script not found: ${CONTAINER_SCRIPT}" >&2
    exit 1
fi

mkdir -p logs "${OUTPUT_DIR}"

INPUT_DIR_ABS="$(cd "${INPUT_DIR}" && pwd -P)"
OUTPUT_DIR_ABS="$(cd "${OUTPUT_DIR}" && pwd -P)"

module load mriqc/24.0.2

if [ ! -e "${MRIQC_IMAGE}" ]; then
    echo "MRIQC image path not found: ${MRIQC_IMAGE}" >&2
    exit 1
fi

singularity_opts=()
if [ -n "${neurodesk_singularity_opts:-}" ]; then
    # Neurodesk exposes this as a small whitespace-separated option string.
    read -r -a singularity_opts <<< "${neurodesk_singularity_opts}"
fi

# The MRIQC container has numpy/pandas/scikit-learn/matplotlib, but not always
# umap-learn. Install the missing package in the user's site-packages so this
# retained script records the environment change needed to rerun the analysis.
singularity --silent exec --cleanenv "${singularity_opts[@]}" \
    --bind "${PROJECT_DIR}:${PROJECT_DIR}" \
    --bind "${INPUT_DIR_ABS}:${INPUT_DIR_ABS}" \
    --bind "${OUTPUT_DIR_ABS}:${OUTPUT_DIR_ABS}" \
    --pwd "${PROJECT_DIR}" \
    "${MRIQC_IMAGE}" \
    python - <<'PY'
import importlib.util
import subprocess
import sys

if importlib.util.find_spec("umap") is None:
    subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", "umap-learn==0.5.12"])
PY

singularity --silent exec --cleanenv "${singularity_opts[@]}" \
    --bind "${PROJECT_DIR}:${PROJECT_DIR}" \
    --bind "${INPUT_DIR_ABS}:${INPUT_DIR_ABS}" \
    --bind "${OUTPUT_DIR_ABS}:${OUTPUT_DIR_ABS}" \
    --pwd "${PROJECT_DIR}" \
    "${MRIQC_IMAGE}" \
    python "${CONTAINER_SCRIPT}" \
        --input-dir "${INPUT_DIR_ABS}" \
        --output-dir "${OUTPUT_DIR_ABS}"
