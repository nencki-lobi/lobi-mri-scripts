#!/bin/bash
set -u

if (( $# != 3 )); then
    echo "Usage: $0 <sub-XX> <bids_dir> <output_dir>"
    exit 1
fi

ml fmriprep

script_dir="$(dirname "${BASH_SOURCE[0]}")"
subj="${1##*-}"
output_dir="$(realpath "$3")"

nprocs=6
mem_mb=10000

mkdir -p "$HOME/fmriprep/$subj"

log_status() {
    printf '%s sub-%s : %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$subj" "$1" \
        | tee -a "$output_dir/checklist.txt"
}

echo "Using MNIPediatricAsym:cohort-2 (4.5-8.5 y/o)"
echo "Using BIDS filter for task Alicja + fmaps without run-XX label"

printf '%s Starting fMRIPrep analysis... Check %s/sub-%s.log for updates\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$output_dir" "$subj"

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS="$nprocs"

fmriprep \
    "$(realpath "$2")" \
    "$output_dir" \
    participant \
    --participant-label "$subj" \
    --fs-license-file "$HOME/shared_storage/freesurfer.txt" \
    --fs-no-reconall \
    --bids-filter-file "$script_dir/fmriprep/bids_filter_alicja_with_fieldmap.json" \
    --nprocs "$nprocs" \
    --mem_mb "$mem_mb" \
    --skip_bids_validation \
    --fd-spike-threshold 0.5 \
    --skull-strip-template MNIPediatricAsym:cohort-2 \
    --output-spaces MNIPediatricAsym:cohort-2:res-2 \
    -w "$HOME/fmriprep/$subj" \
    -v > "$output_dir/sub-${subj}.log" 2>&1

# QC
if find "$output_dir/sub-$subj" -type f \
    -name '*desc-preproc_bold.nii.gz' -print -quit | grep -q .; then

    if find "$(realpath "$2")/sub-$subj" -type d \
        -name fmap -print -quit | grep -q .; then

        log_status "Preproc finished. Check $output_dir/sub-${subj}.log for details"
        rm -rf "$HOME/fmriprep/$subj"
    else
        log_status "Finished with problems: BOLD present but fmap missing. Check $output_dir/sub-${subj}.log for details"
    fi
else
    log_status "Finished with problems: no desc-preproc_bold found. Check $output_dir/sub-${subj}.log for details"
fi