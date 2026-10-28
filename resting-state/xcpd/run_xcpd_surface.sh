#!/bin/bash
set -u

if (( $# != 3 )); then
    echo "Usage: $0 <sub-XX> <fmriprep_dir> <output_dir>"
    exit 1
fi

ml xcpd/26.2.0

subj="${1##*-}"
output_dir="$(realpath "$3")"

nprocs=6
mem_mb=10000

printf '%s Starting XCP-D analysis... Check %s/sub-%s.log for updates\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$output_dir" "$subj"

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS="$nprocs"
export APPTAINERENV_TEMPLATEFLOW_HOME=/home/jovyan/templateflow

xcp_d \
    "$(realpath "$2")" \
    "$output_dir" \
    participant \
    --mode linc \
    --participant-label "$subj" \
    --task-id rest \
    --file-format cifti \
    --fs-license-file "$HOME/shared_storage/freesurfer.txt" \
    --nprocs "$nprocs" \
    --mem-mb "$mem_mb" \
    -w "$HOME/xcpd/$subj" \
    > "$output_dir/sub-${subj}.log" 2>&1

printf '%s Finished XCP-D analysis. Check %s/sub-%s.log for details\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$output_dir" "$subj"
