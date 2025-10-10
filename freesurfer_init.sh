#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Provide SUBECTS_DIR as argument eg. $0 ./bids-dir/derivatives/freesurfer"
  exit 1
fi

SUBJECTS_DIR="$1"
mkdir -p "$SUBJECTS_DIR"

export FS_LICENSE=/home/jovyan/shared_storage/freesurfer.txt
export SUBJECTS_DIR="$SUBJECTS_DIR"
export APPTAINERENV_SUBJECTS_DIR="$SUBJECTS_DIR"

export FS_ALLOW_DEEP=1
export APPTAINERENV_FS_ALLOW_DEEP="$FS_ALLOW_DEEP"

echo "SUBJECTS_DIR=$SUBJECTS_DIR"
echo "Loading freesurfer..."
ml freesurfer
recon-all -version