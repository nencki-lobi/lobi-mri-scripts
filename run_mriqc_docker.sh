root_dir=$(realpath "$2")
subj=${1##*-}

nthreads=10
mem=20 #gb

echo docker run --rm --network none -v $root_dir:/mnt nipreps/mriqc \
/mnt/ /mnt/derivatives/mriqc  \
participant \
--participant-label ${subj} \
--fd_thres 0.5 \
--n_proc $nthreads \
--mem_gb $mem \
--float32 \
--ants-nthreads $nthreads \
--verbose-reports \
--no-sub \
--modalities T1w bold
