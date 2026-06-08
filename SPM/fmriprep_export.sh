#!/usr/bin/env bash
set -euo pipefail

CUSTOM_CONFOUNDS=FALSE

sub="$1"
task="$2"

script_dir="$(cd "$(dirname "$0")" && pwd)"
confounds_script="$script_dir/extract-confounds-to-spm.sh"

if [[ "$CUSTOM_CONFOUNDS" == "FALSE" && ! -x "$confounds_script" ]]; then
    cat <<EOF

Script extract-confounds-to-spm.sh is missing for operation.

Execute:
    lobi_scripts add SPM/extract-confounds-to-spm.sh ./code

and run fmriprep_export.sh again.

EOF
    exit 1
fi

for ses_dir in derivatives/fmriprep/"$sub"/ses-*; do

    ses="$(basename "$ses_dir")"

    if [[ -d "$ses_dir/fmap" ]]; then
        outsub="$sub"
    else
        echo "  WARNING: no fieldmap folder found for $sub $ses"
        outsub="${sub}_uncorr"
    fi

    outdir="derivatives/spm/$outsub/$task"
    mkdir -p "$outdir"

    echo "$sub $ses -> $outdir"

    for f in \
        "$ses_dir"/func/*task-"$task"*space-MNI*desc-preproc_bold.nii.gz \
        "$ses_dir"/func/*task-"$task"*space-MNI*desc-brain_mask.nii.gz
    do
        [[ -e "$f" ]] || continue
        gunzip -c "$f" > "$outdir/$(basename "$f" .gz)"
    done

    if [[ "$CUSTOM_CONFOUNDS" == "FALSE" ]]; then
        for f in "$ses_dir"/func/*task-"$task"*desc-confounds_timeseries.tsv; do
            [[ -e "$f" ]] || continue

            base="$(basename "$f" _desc-confounds_timeseries.tsv)"

            "$confounds_script" \
                "$f" \
                "$outdir/${base}_multiple_regressors.txt"
        done
    fi

done