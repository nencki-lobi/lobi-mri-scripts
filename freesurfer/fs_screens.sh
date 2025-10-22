#usage: ./fs_screens.sh sub-XX
subj=$1
# mri/aseg.mgz:colormap=lut:opacity=0.2
freeview -v $subj/mri/brainmask.mgz \
              -f $subj/surf/lh.pial:edgecolor=red $subj/surf/rh.pial:edgecolor=red \
                 $subj/surf/lh.white:edgecolor=yellow $subj/surf/rh.white:edgecolor=yellow \
              -viewport coronal -layout 1 \
              -slice 127 127 128 -ss "$subj".png