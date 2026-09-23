#!/bin/bash
set -u

if (( $# != 3 )); then
    echo "Usage: $0 <sub-XX> <bids_dir> <output_dir>"
    exit 1
fi

ml fmriprep

subj="${1##*-}"
output_dir="$(realpath "$3")"
fs_subjects_dir="$HOME/freesurfer-subjects-dir"

nprocs=6
mem_mb=10000

mkdir -p "$HOME/fmriprep/$subj" "$fs_subjects_dir"

log_status() {
    printf '%s sub-%s : %s\n' \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$subj" "$1" \
        | tee -a "$output_dir/checklist.txt"
}

printf '%s Starting fMRIPrep analysis... Check %s/sub-%s.log for updates\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$output_dir" "$subj"

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS="$nprocs"

fmriprep \
    "$(realpath "$2")" \
    "$output_dir" \
    participant \
    --participant-label "$subj" \
    --bids-filter-file "$HOME/fmriprep-reconed/bids_filter.json" \
    --fs-license-file "$HOME/shared_storage/freesurfer.txt" \
    --fs-subjects-dir "$fs_subjects_dir" \
    --output-spaces MNI152NLin2009cAsym:res-native fsnative \
    --cifti-output 91k \
    --nprocs "$nprocs" \
    --mem_mb "$mem_mb" \
    --skip_bids_validation \
    --fd-spike-threshold 0.5 \
    -w "$HOME/fmriprep/$subj" \
    -v > "$output_dir/sub-${subj}.log" 2>&1

# QC
if find "$output_dir/sub-$subj" -type f \
    -name '*desc-preproc_bold.nii.gz' -print -quit | grep -q .; then

    if find "$(realpath "$2")/sub-$subj" -type d \
        -name fmap -print -quit | grep -q .; then

        log_status "Preproc finished. Check $output_dir/sub-${subj}.log for details"
        echo 'Run: rm -rf "$HOME/fmriprep/$subj" if you want to delete the temporary files.'
        #rm -rf "$HOME/fmriprep/$subj"
    else
        log_status "Finished with problems: BOLD present but fmap missing. Check $output_dir/sub-${subj}.log for details"
    fi
else
    log_status "Finished with problems: no desc-preproc_bold found. Check $output_dir/sub-${subj}.log for details"
fi