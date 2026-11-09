#!/bin/bash
# Usage: bash run_cpac.sh <subject> <input_dir> <output_dir> [session]
# Example: bash run_cpac.sh sub-MM030926 /dane/fmriprep /wyniki ses-02
# Subject may be given with or without sub-; session defaults to 01.
# Session may be given with or without ses-.
set -euo pipefail

script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
subj="${1#sub-}"
input_dir="$(realpath -m "$2")"
output_dir="$(realpath -m "$3")"
session="${4:-01}"
session="ses-${session#ses-}"
session_dir="$input_dir/sub-${subj}/$session"
prefix="sub-${subj}_${session}"
template="MNI152NLin2009cAsym"

mkdir -p "$output_dir"

# Keep the TSV header and replace fMRIPrep n/a values in a copy.
confounds="$session_dir/func/${prefix}_task-rest_desc-confounds_timeseries.tsv"
clean_confounds="$output_dir/${prefix}_task-rest_desc-confounds_timeseries.tsv"
{ head -n 1 "$confounds"; tail -n +2 "$confounds" | sed 's/\<n\/a\>/0/g'; } > "$clean_confounds"

# Bind input files and their JSON sidecars
bindings=(
    -B "$session_dir/anat/${prefix}_acq-norm_space-${template}_desc-brain_mask.nii.gz:/input/anat/${prefix}_acq-norm_space-${template}_desc-brain_mask.nii.gz:ro"
    -B "$session_dir/anat/${prefix}_acq-norm_space-${template}_desc-brain_mask.json:/input/anat/${prefix}_acq-norm_space-${template}_desc-brain_mask.json:ro"

    -B "$session_dir/func/${prefix}_task-rest_space-${template}_desc-preproc_bold.nii.gz:/input/func/${prefix}_task-rest_space-${template}_desc-preproc_bold.nii.gz:ro"
    -B "$session_dir/func/${prefix}_task-rest_space-${template}_desc-preproc_bold.json:/input/func/${prefix}_task-rest_space-${template}_desc-preproc_bold.json:ro"

    -B "$session_dir/func/${prefix}_task-rest_space-${template}_desc-brain_mask.nii.gz:/input/func/${prefix}_task-rest_space-${template}_desc-brain_mask.nii.gz:ro"
    -B "$session_dir/func/${prefix}_task-rest_space-${template}_desc-brain_mask.json:/input/func/${prefix}_task-rest_space-${template}_desc-brain_mask.json:ro"

    -B "$clean_confounds:/input/func/${prefix}_task-rest_desc-confounds_timeseries.tsv:ro"
    -B "$session_dir/func/${prefix}_task-rest_desc-confounds_timeseries.json:/input/func/${prefix}_task-rest_desc-confounds_timeseries.json:ro"
)

nprocs=6
mem_gb=10

data_config="$output_dir/data_config.yaml"
printf -- '- subject_id: sub-%s\n  unique_id: %s\n  derivatives_dir: /input\n' \
    "$subj" "$session" > "$data_config"

printf 'Participant: sub-%s\nSession: %s\nInput: %s\nOutput: %s\nData config: %s\nClean confounds: %s\n' \
    "$subj" "$session" "$input_dir" "$output_dir" "$data_config" "$clean_confounds"

printf '%s Starting C-PAC analysis... Check %s/sub-%s.log for updates\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$output_dir" "$subj"

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS="$nprocs"
export OMP_NUM_THREADS="$nprocs"

cpac \
    --platform singularity \
    "${bindings[@]}" \
    --image "$script_dir/c-pac.sif" \
    run \
    none \
    "$output_dir" \
    participant \
    --pipeline-file pipeline.yml \
    --data-config-file "$data_config" \
    --participant_label "$subj" \
    --n_cpus "$nprocs" \
    --mem_gb "$mem_gb" \
    > "$output_dir/sub-${subj}.log" 2>&1

    #--pipeline-file "$script_dir/pipeline.yml" \
