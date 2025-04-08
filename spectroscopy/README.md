## ls_dat.sh - get meaningful Patient ID from Siemens RAW file

Prepare Your dictionary with relevant subjects' names using ls_dat.sh

```
ls *.dat | xargs -n 1 ~/ls_dat.sh > list.csv
```

Example of list.csv after some text processing:
```
twix,PatientName,bids_code
mjris#Sprisma#F9543#M209#D100223#T153155#nawm_ris_special.dat,MJRIS_004,4
mjris#Sprisma#F9545#M211#D100223#T153643#nawm_ris_special_NWS.dat,MJRIS_004,4
```

[Then You can follow our manual for MRS2BIDS](MRS2BIDS.md)

## equalize.py - itertively apodize MRS to a target FWHM of Creatine peak

python equalize.py rest.nii.gz stim.nii.gz will check initial width of Creatine peak and iteratively apodize one of them to match target value. You can use optional arguments such as:
```
--fwhm_target XX to provide subjective target value
--basis_location to modify the default basis set
``

