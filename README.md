Manual for DICOM to BIDS is available on our website [lobi.nencki.gov.pl/dla-badaczy/know-how/data-export)](https://sites.google.com/nencki.edu.pl/lobi-informacja-dla-badaczy/know-how/data-export)

Available run scripts:

```
./run_dcm2bids.sh xnat_id subject [session]

./run_mriqc.sh subject bids_dir

./run_fmriprep_min.sh subject bids_dir

```
Caution! Currently fmriprep does not recognize BIDS-URIs produced by dcm2bids. Please run first ``find bids_root -iname *dir*.json -exec ./fmriprep/json_fmaps_repair.sh {} \;``


