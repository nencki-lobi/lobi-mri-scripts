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

But it uses dcm2niix, which does not recognize Siemens DAT files, thus first You'll need to manually convert and save them in the temporary directory (the one to be used by dcm2bids).

Use ls_dat.sh to get Patients' IDs and spec2nii to convert TWIX files as in the example below:

```
tail -n +2 ./list.csv | parallel -j 4 --colsep ',' echo spec2nii twix -e image -j -o tmp_dcm2bids/sub-{3}_ses-01 sourcedata/spectro/{1}
```

Run dcm2bids again to sort them out.