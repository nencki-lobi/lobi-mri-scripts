#!/bin/bash
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <sub-XX> <bids_dir> <bids_dir/derivatives/fmriprep>"
    exit 1
fi
ml fmriprep

root_dir=$(realpath "$2")
subj=${1##*-}
output_dir=$(realpath "$3")
work=$(realpath ~/fmriprep)

mkdir -p $work/$subj
mkdir -p ~/freesurfer-subjects-dir #if not exists will give error

nprocs=6
mem=10000 #mb

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$nprocs
fmriprep $root_dir \
         $output_dir \
         participant \
         --fs-license-file ~/shared_storage/freesurfer.txt \
         --fs-no-reconall \
         --participant-label $subj \
         --nprocs $nprocs --mem_mb $mem \
         --skip_bids_validation \
         -w $work/$subj \
         --fd-spike-threshold 0.5 \
         -v

# ----- QC CHECK -----

logfile="$root_dir/derivatives/fmriprep.log"

if find "$output_dir/sub-$subj" -type f -name "*desc-preproc_bold.nii.gz" -print -quit | grep -q .; then
    if ! find "$root_dir/sub-$subj" -type d -name fmap | grep -q .; then
        echo "$(date) sub-$subj : BOLD present but fmap missing" >> "$logfile"
    else
        echo "$(date) sub-$subj : Preproc finished" >> "$logfile"
        rm -rf $work/$subj
    fi

else
    echo "$(date) sub-$subj : Preproc failed (no desc-preproc_bold found)" >> "$logfile"
fi


