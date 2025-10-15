
## 🧠 LOBI Scripts for MRI Data Processing

**[Quickstart.ipynb](./quickstart.ipynb)** demonstrates how to use Neurodesk, the [xnat_dcm2bids module](https://github.com/nencki-lobi/xnat_dcm2bids/tree/main/xnat_dcm2bids), and the scripts provided in this repository.

Specifically, you will find the following resources here:


### 📁 dcm2bids configs

Custom configuration files for our projects:
➡️ [`./dcm2bids`](./dcm2bids)


### ⚙️ Available run scripts

* **[`freesurfer_init.sh subjects_dir`](./freesurfer_init.sh)**
  Initializes environment variables and Freeview aliases.

* **[`run_mriqc.sh subject bids_dir`](./run_mriqc.sh)**
  Runs **MRIQC** with custom resource settings and working directory.
  The framewise displacement (FD) threshold is set to `0.3` (adjust if needed).

* **[`run_fmriprep_min.sh subject bids_dir`](./run_fmriprep_min.sh)**
  Runs **fMRIPrep** with custom resource settings and working directory, **without** FreeSurfer reconstruction.

* **[`run_fmriprep_kids_alicja.sh subject bids_dir`](./run_fmriprep_kids_alicja.sh)**
  Fully customized **fMRIPrep** pipeline with:

  * cohort-specific atlas from **TemplateFlow**,
  * **BIDS filtering** to include only specific task names and selected fieldmaps **without the `run-xx` label** (note: fMRIPrep will not report missing fieldmaps but gives an error when there are multiple ones available).

* **[`run_dcm2bids_noauto.sh xnat_id subject [session]`](./run_dcm2bids_noauto.sh)**
  ⚠️ **Deprecated:** this script has been replaced by the
  [xnat_dcm2bids](https://github.com/nencki-lobi/xnat_dcm2bids/tree/main/xnat_dcm2bids) module
  with the flag `--auto_extract_entities False`.  
  **Caution:** currently, [fMRIPrep does not recognize BIDS-URIs](https://github.com/nipreps/sdcflows/pull/349)
  produced by `dcm2bids` and the `run_dcm2bids_noauto.sh` script.
  Please repair fieldmap JSONs using the following command:
  `find bids_root -iname "*dir*.json" -exec ./fmriprep/json_fmaps_repair.sh {} \;`



When using the [xnat_dcm2bids](https://github.com/nencki-lobi/xnat_dcm2bids/tree/main/xnat_dcm2bids) module,
you can call these scripts conveniently via the `lobi_script` command:
`lobi_script run_mriqc.sh sub-xx ./derivatives/mriqc` or `lobi_script ls
` to list all available scripts.


