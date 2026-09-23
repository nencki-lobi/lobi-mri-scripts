#!/bin/bash
set -u

if (( $# != 3 )); then
    echo "Usage: $0 <sub-XX> <bids_dir> <output_dir>"
    exit 1
fi

script_dir="$(dirname "${BASH_SOURCE[0]}")"
mriqc_ver="$script_dir/mriqc/mriqc-wrapper"

if [[ "$mriqc_ver" == "$script_dir/mriqc/mriqc-wrapper" ]]; then
    echo "CAUTION: using modified MRIQC pipeline"
fi

ml mriqc

subj="${1##*-}"
output_dir="$(realpath "$3")"

nthreads=10
mem_gb=20

mkdir -p "$HOME/mriqc/$subj"

printf '%s Starting MRIQC analysis... Check %s/sub-%s.log for updates\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$output_dir" "$subj"

"$mriqc_ver" \
    "$(realpath "$2")" \
    "$output_dir" \
    participant \
    --participant-label "$subj" \
    --fd_thres 0.5 \
    --n_proc "$nthreads" \
    --mem_gb "$mem_gb" \
    --float32 \
    --ants-nthreads "$nthreads" \
    --verbose-reports \
    --no-sub \
    --modalities T1w T2w bold \
    -w "$HOME/mriqc/$subj" \
    > "$output_dir/sub-${subj}.log" 2>&1

rm -rf "$HOME/mriqc/$subj"

printf '%s Finished MRIQC analysis. Check %s/sub-%s.log for details\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$output_dir" "$subj"

echo
echo "Now you can run group level with:"
echo "\"$mriqc_ver\" \"$(realpath "$2")\" \"$output_dir\" group -w \"$HOME/mriqc\""