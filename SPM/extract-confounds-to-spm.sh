#!/bin/bash

# check args
if [ $# -ne 2 ]; then
    echo "Usage: $0 <fmriprep_confounds.tsv> <spm_multiple_regressors.txt>"
    exit 1
fi

INFILE="$1"
OUTFILE="$2"

# extract header with column numbers
HEADER=$(head -n1 "$INFILE" | tr '\t' '\n' | nl -w1 -s:)

# select motion columns by name
COLS=$(echo "$HEADER" \
    | grep -E ':(trans_x|trans_y|trans_z|rot_x|rot_y|rot_z|motion_outlier.*)$' \
    | cut -d: -f1 \
    | paste -sd, -)

# cut columns and remove header
cut -f"$COLS" "$INFILE" \
  | tail -n +2 \
  | sed 's/\<n\/a\>/0/g' \
  > "$OUTFILE"

echo "Saved to $OUTFILE"
