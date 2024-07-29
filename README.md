## LOBI scripts for MRI data processing

A general manual on dealing with MRI data is available on our website [lobi.nencki.gov.pl/dla-badaczy/know-how/get-data)](https://sites.google.com/nencki.edu.pl/lobi-informacja-dla-badaczy/know-how/get-data)

Available run scripts:

```
./run_dcm2bids.sh xnat_id subject [session]

./run_dcm2bids_noauto.sh xnat_id subject [session] - to be used without --auto_extract_entities i.e. runs

./run_mriqc.sh subject bids_dir

./run_fmriprep_min.sh subject bids_dir

```
Caution! Currently [fmriprep does not recognize BIDS-URIs](https://github.com/nipreps/sdcflows/pull/349) produced by dcm2bids. Please repair fieldamaps' jsons with this command first:
```
find bids_root -iname "*dir*.json" -exec ./fmriprep/json_fmaps_repair.sh {} \;
```


