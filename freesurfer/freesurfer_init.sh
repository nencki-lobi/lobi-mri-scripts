#!/bin/bash

SUBJECTS_DIR="$1"
if [ $# -lt 1 ]; then
    SUBJECTS_DIR="$(pwd)"
fi

mkdir -p "$SUBJECTS_DIR"

export FS_LICENSE=/home/jovyan/shared_storage/freesurfer.txt
export SUBJECTS_DIR="$SUBJECTS_DIR"
export APPTAINERENV_SUBJECTS_DIR="$SUBJECTS_DIR"

export FS_ALLOW_DEEP=1
export APPTAINERENV_FS_ALLOW_DEEP="$FS_ALLOW_DEEP"

echo "SUBJECTS_DIR=$SUBJECTS_DIR"

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
	echo "Loading freesurfer..."
	ml freesurfer
	recon-all -version

    echo "Setting aliases: fsaseg, fsbrainmask, fswm, fst1, fsaparc"
    alias fsaseg='freeview -v mri/brainmask.mgz mri/aseg.mgz:colormap=lut:opacity=0.2 -f surf/lh.pial:edgecolor=red surf/rh.pial:edgecolor=red surf/lh.white:edgecolor=yellow surf/rh.white:edgecolor=yellow'
    alias fsbrainmask='freeview -v mri/brainmask.mgz -f surf/lh.pial:edgecolor=red surf/rh.pial:edgecolor=red surf/lh.white:edgecolor=yellow surf/rh.white:edgecolor=yellow'
    alias fswm='freeview -v mri/wm.mgz mri/brainmask.mgz -f surf/lh.pial:edgecolor=red surf/rh.pial:edgecolor=red surf/lh.white:edgecolor=yellow surf/rh.white:edgecolor=yellow'
    alias fst1='freeview -v mri/T1.mgz'
    alias fsaparc='freeview -v mri/orig.mgz mri/aparc+aseg.mgz:colormap=lut:opacity=0.4 -f surf/lh.white:annot=aparc.annot'
else
	echo "Now You can load freesurfer eg. ml freesurfer"
fi
