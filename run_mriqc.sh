#!/bin/bash
#usage: ./run_mriqc.sh <sub-XX> <bids_dir> <bids-dir/derivatives/mriqc>
ml mriqc

script_dir="$(dirname "${BASH_SOURCE[0]}")"

mriqc_ver=mriqc
#mriqc_ver=$script_dir/mriqc/mriqc-wrapper

if [ "$mriqc_ver" = "$script_dir/mriqc/mriqc-wrapper" ]; then
	echo "using: mriqc mod to force fber calculation"
fi

bids_dir=$(realpath "$2")
output_dir=$(realpath "$3")
subj=${1##*-}
work=$(realpath ~/mriqc)

mkdir -p $work/$subj
nthreads=10
mem=20 #gb

echo $work
echo $mriqc_ver \
    $bids_dir \
    $output_dir \
    participant \
    --participant-label ${subj} \
    --fd_thres 0.3 \
    --n_proc $nthreads \
    --mem_gb $mem \
    --float32 \
    --ants-nthreads $nthreads \
    --verbose-reports \
    --no-sub \
    -w $work/$subj \
    --modalities bold

rm -rf $work/$subj

echo
echo "Now You can run group level with:"
echo "$mriqc_ver $bids_dir $output_dir group"

