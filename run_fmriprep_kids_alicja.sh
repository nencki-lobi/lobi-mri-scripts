ml fmriprep

echo "using: MNIPediatricAsym:cohort-2 which is adequate for 4.5 - 8.5 y/o"
#res-1 is 1mm

echo "using: bids filter for task Alicja + fmaps"
script_dir="$(dirname "${BASH_SOURCE[0]}")"

root_dir=$(realpath "$2")
output_dir=$(realpath "$3")
subj=${1##*-}
work=$(realpath ~/fmriprep)

mkdir -p $work/$subj

nprocs=6
mem=10000 #mb

export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$nprocs
fmriprep $root_dir \
         $output_dir \
         participant \
         --fs-license-file ~/freesurfer.txt \
         --fs-no-reconall \
         --participant-label $subj \
         --bids-filter-file $scipt_dir/fmriprep/bids_filter_alicja.json \
         --nprocs $nprocs --mem_mb $mem \
         --skip_bids_validation \
         -w $work/$subj \
         --fd-spike-threshold 0.5 \
         --skull-strip-template MNIPediatricAsym:cohort-2 \
         --output-spaces MNIPediatricAsym:cohort-2:res-2 \
         -v

rm -rf $work/$subj
