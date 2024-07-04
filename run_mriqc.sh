ml mriqc

root_dir=$(realpath "$2")
subj=${1##*-}
work=$(realpath ~/mriqc)

mkdir -p $work/$subj
nthreads=10
mem=20 #gb

echo mriqc \
$root_dir $root_dir/derivatives/mriqc  \
participant \
--participant-label ${subj} \
--fd_thres 0.5 \
--n_proc $nthreads \
--mem_gb $mem \
--float32 \
--ants-nthreads $nthreads \
--verbose-reports \
--no-sub \
-w $work/$subj \
--modalities T1w

rm -rf $work/$subj
