ml fmriprep

root_dir=$(realpath "$2")
subj=${1##*-}
work=$(realpath ~/fmriprep)

mkdir -p $work/$subj

nprocs=6
mem=10000 #mb

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$nprocs
fmriprep $root_dir \
         $root_dir/derivatives \
         participant \
         --fs-license-file $root_dir/code/freesurfer.txt \
         --fs-no-reconall \
         --participant-label $subj \
         --nprocs $nprocs --mem_mb $mem \
         --skip_bids_validation \
         -w $work/$subj \
         -v

rm -rf $work/$subj
