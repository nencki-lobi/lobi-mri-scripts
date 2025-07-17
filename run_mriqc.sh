ml mriqc

root_dir=$(realpath "$2")
output_dir=$(realpath "$3")
subj=${1##*-}
work=$(realpath ~/mriqc)

mkdir -p $work/$subj
nthreads=10
mem=20 #gb

echo $work
~/mriqc-wrapper \
$root_dir $output_dir \
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
--modalities T1w bold

rm -rf $work/$subj
