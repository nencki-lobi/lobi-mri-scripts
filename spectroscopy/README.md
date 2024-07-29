## How to convert Siemens TWIX spectroscopy to NiFTI/BIDS

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

You can dcm2bids and relevant configuration such as:

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

But first You'll need to manually save spectroscopy as NiFTI files.
Use spec2nii to convert TWIX files and place them in tmp_dcm2bids:

```
tail -n +2 ./list.csv | parallel -j 4 --colsep ',' echo spec2nii twix -e image -j -o tmp_dcm2bids/sub-{3}_ses-01 sourcedata/spectro/{1}
```

Run dcm2bids again

