#!/bin/bash
set -u

if (( $# != 3 )); then
    echo "Usage: $0 <sub-XX> <fmriprep_dir> <output_dir>"
    exit 1
fi

ml xcp_d

subj="${1##*-}"
output_dir="$(realpath "$3")"

nprocs=6
mem_gb=10

printf '%s Starting XCP-D analysis... Check %s/sub-%s.log for updates\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$output_dir" "$subj"

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS="$nprocs"

xcp_d \
    "$(realpath "$2")" \
    "$output_dir" \
    participant \
    --mode linc \
    --participant-label "$subj" \
    --task-id rest \
    --file-format nifti \
    --nprocs "$nprocs" \
    --mem-gb "$mem_gb" \
    > "$output_dir/sub-${subj}.log" 2>&1

printf '%s Finished XCP-D analysis. Check %s/sub-%s.log for details\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$output_dir" "$subj"
