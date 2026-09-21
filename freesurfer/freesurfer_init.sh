if ! grep -q "FS_LICENSE" "$PROFILE" 2>/dev/null; then
cat >> "$PROFILE" <<'EOF'

# >>> FreeSurfer setup >>>
export FS_LICENSE=/home/jovyan/shared_storage/freesurfer.txt
export FS_ALLOW_DEEP=1

if [ -z "${SUBJECTS_DIR:-}" ]; then
    export SUBJECTS_DIR="$HOME"
fi

export APPTAINERENV_SUBJECTS_DIR="$SUBJECTS_DIR"
export APPTAINERENV_FS_ALLOW_DEEP="$FS_ALLOW_DEEP"

alias fsaseg='freeview -v mri/brainmask.mgz mri/aseg.mgz:colormap=lut:opacity=0.2 -f surf/lh.pial:edgecolor=red surf/rh.pial:edgecolor=red surf/lh.white:edgecolor=yellow surf/rh.white:edgecolor=yellow'
alias fsbrainmask='freeview -v mri/brainmask.mgz -f surf/lh.pial:edgecolor=red surf/rh.pial:edgecolor=red surf/lh.white:edgecolor=yellow surf/rh.white:edgecolor=yellow'
alias fswm='freeview -v mri/wm.mgz mri/brainmask.mgz -f surf/lh.pial:edgecolor=red surf/rh.pial:edgecolor=red surf/lh.white:edgecolor=yellow surf/rh.white:edgecolor=yellow'
alias fst1='freeview -v mri/T1.mgz'
alias fsaparc='freeview -v mri/orig.mgz mri/aparc+aseg.mgz:colormap=lut:opacity=0.4 -f surf/lh.white:annot=aparc.annot'
# <<< FreeSurfer setup <<<
EOF
    echo
    echo "Freesurfer został dodany do ~/.profile."
    echo "Uruchom ponownie środowisko lub wykonaj:"
    echo
    echo "    source ~/.profile"
    echo
fi
