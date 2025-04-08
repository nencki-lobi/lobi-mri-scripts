## Sorting MRS with dcm2bids

Dcm2bids will handle NIFTI MRS with a use of relevant configuration such as:

```
    {
        "datatype": "mrs",
        "suffix": "svs",
        "custom_entities": "label-lesion",
        "criteria": {
            "ProtocolName": "lesion_ris_special"
        }
    }
```

But it uses dcm2niix, which does not recognize Siemens DAT files, thus first You'll need to manually convert and save them in the temporary directory used by dcm2bids ($bids_dir/tmp_dcm2bids).

Use ls_dat.sh to get Patients' IDs and spec2nii to convert dats to NIFTIs:

```
twix,PatientName,bids_code
mjris#Sprisma#F9543#M209#D100223#T153155#nawm_ris_special.dat,MJRIS_004,4
mjris#Sprisma#F9545#M211#D100223#T153643#nawm_ris_special_NWS.dat,MJRIS_004,4
```

```
tail -n +2 ./list.csv | parallel -j 4 --colsep ',' echo spec2nii twix -e image -j -o tmp_dcm2bids/sub-{3}_ses-01 sourcedata/spectro/{1}
```
, where  
{1} will be replaced by twix filenames  
{3} will be replaced by subjects' codes

Finally run dcm2bids again to rename and sort them according to its configuration file.