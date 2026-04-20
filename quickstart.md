# Quickstart Tutorial: Neurodesktop & BIDS Conversion

Welcome! This tutorial will guide you through:

- Launching Neurodesktop tools
- Converting XNAT DICOM data to BIDS format
- Running common neuroimaging pipelines such as MRIQC and fMRIPrep

## Table of Contents

- [1. Intro](#1-intro)
- [2. Data Conversion](#2-data-conversion)
  - [2.1 Install xnat_dcm2bids](#21-install-xnat_dcm2bids)
  - [2.2 Important Tools and Links](#22-important-tools-and-links)
  - [2.3 Configure XNAT Connection](#23-configure-xnat-connection)
  - [2.4 Download Session List](#24-download-session-list)
  - [2.5 Prepare BIDS Directory](#25-prepare-bids-directory)
  - [2.6 Set Up the Config File](#26-set-up-the-config-file)
  - [2.7 Run Conversion](#27-run-conversion)
- [3. Software and Pipelines](#3-software-and-pipelines)
  - [3.1 lobi_scripts](#31-lobi_scripts)
  - [3.2 MRIQC and fMRIPrep](#32-mriqc-and-fmriprep)
  - [3.3 Preinstalled Software](#33-preinstalled-software)
  - [3.4 Loading Software from the Neurodesk Repo](#34-loading-software-from-the-neurodesk-repo)
  - [3.5 Installing New Software](#35-installing-new-software)
- [FAQ](FAQ.md)

## 1. Intro

You can follow this tutorial from Jupyter Notebook or from Terminal. The commands below are written as regular shell commands, so you can run them directly in Terminal.

Start by launching Neurodesktop and choosing one of the following:

- **Terminal**
- **Jupyter Notebook**
- **Remote Desktop (Neurodesktop GUI)**

In the Neurodesktop GUI you can run MATLAB, FSL, Freeview, and other programs directly. See [Software and Pipelines](#3-software-and-pipelines) for details.

## 2. Data Conversion

### 2.1 Install `xnat_dcm2bids`

You can install this package on your own macOS, Windows, or Linux machine using pip:

```bash
pip install https://github.com/nencki-lobi/xnat_dcm2bids/archive/refs/heads/master.zip
```

### 2.2 Important Tools and Links

Fundamental tools:

- **`dcm2bids_scaffold`** prepares a new BIDS directory.

```bash
dcm2bids_scaffold -o ~/bids-dir
```

- **`xnat_getcsv`** downloads a session list to CSV.

```bash
xnat_getcsv -o list.csv public
```

- **`xnat_dcm2bids`** downloads data from a selected XNAT session, for example `f490f566-2124-46`, and converts it to BIDS format using `dcm2bids`.

```bash
xnat_dcm2bids --output-dir ~/bids-dir --config ~/bids-dir/code/config.json f490f566-2124-46 03 01
```

- **`lobi_scripts`** manages reference scripts from [lobi-mri-scripts](https://github.com/nencki-lobi/lobi-mri-scripts).

Other tools installed alongside:

- **`xnat-get`** downloads all DICOM files from XNAT.

```bash
xnat-get -p public -t ./sourcedata
```

- **`xnat-ls`** sets up the connection and lists sessions from XNAT.

```bash
xnat-ls -p public
```

Find out more in the [xnat_dcm2bids repository](https://github.com/nencki-lobi/xnat_dcm2bids).

### 2.3 Configure XNAT Connection

The `xnat_dcm2bids` tools use a specific authentication method. If you see a connection error, try `xnat-ls` to establish the connection. The first-time setup must be done in Terminal: run `xnat-ls`, then provide `xnat.nencki.edu.pl` as the URL and enter your credentials.

Expected output is a list of all available projects.

### 2.4 Download Session List

To download a list of all available XNAT sessions from project `public`, run:

```bash
cd ~
xnat_getcsv -o list.csv public
```

If you want to preview the CSV content in Python:

```python
import pandas as pd

df = pd.read_csv("~/list.csv", dtype=str, index_col=0)
df.head(10)
```

### 2.5 Prepare BIDS Directory

Create a new BIDS scaffold and move into the project directory:

```bash
dcm2bids_scaffold -o ~/bids-dir
cd ~/bids-dir
ls -1 ~/bids-dir
```

### 2.6 Set Up the Config File

Usually, we provide you with a customized configuration for `dcm2bids`. Ready-made configurations are available in the [`dcm2bids`](./dcm2bids) directory of this repository.

The `~/lobi-mri-scripts` directory should stay a shared source repository. Do not edit files there. Keep your project-specific copies in `~/bids-dir/code`, and link or copy them from the repository when needed:

```bash
ln -sf ~/lobi-mri-scripts/dcm2bids/mjris.json ~/bids-dir/code/config.json
```

Below is an example configuration for a basic experiment consisting of T1w, task fMRI, and field maps:

```json
{
  "descriptions": [
    {
      "datatype": "anat",
      "suffix": "T1w",
      "criteria": {
        "SeriesDescription": "anat_t1w"
      }
    },
    {
      "id": "fmri",
      "datatype": "func",
      "suffix": "bold",
      "criteria": {
        "SeriesDescription": "task-*"
      }
    },
    {
      "datatype": "fmap",
      "suffix": "epi",
      "criteria": {
        "SeriesDescription": "SpinEchoFieldMap*"
      },
      "sidecar_changes": {
        "intendedFor": ["fmri"]
      }
    }
  ]
}
```

### 2.7 Run Conversion

Single-session example:

- XNAT session ID: `tstdtst`
- Subject: `03`
- Session: `01`

```bash
cd ~/bids-dir
xnat_dcm2bids --output-dir ~/bids-dir --config ~/bids-dir/code/config.json tstdtst 03 01
```

Multiple sessions from CSV:

```bash
cd ~/bids-dir
while IFS=',' read -r xnatid patient date sub ses _; do
  echo xnat_dcm2bids --output-dir ~/bids-dir --config ~/bids-dir/code/config.json "$xnatid" "$sub" "$ses"
done < ~/list.csv
```

Remove `echo` to execute the commands.

## 3. Software and Pipelines

This section covers the software and pipelines used for MRI data processing. First, let's look at the available reference scripts in the `lobi_scripts` repository. Then you will learn how to use MATLAB, FSL, and other tools available in Neurodesk.

### 3.1 `lobi_scripts`

**Copy the scripts you need into your project directory, edit the local copies there, and run those local versions.**

Example workflow:

```bash
lobi_scripts install
lobi_scripts ls
lobi_scripts add run_mriqc.sh ~/bids-dir/code
~/bids-dir/code/run_mriqc.sh 03 ~/bids-dir ~/bids-dir/derivatives/mriqc
```

**We recommend updating the repository frequently with `lobi_scripts update` and using the latest versions of the scripts and manuals.**

Example commands:

```bash
lobi_scripts ls
lobi_scripts add run_mriqc.sh ~/bids-dir/code
lobi_scripts add run_fmriprep_min.sh ~/bids-dir/code
lobi_scripts update
lobi_scripts diff ~/bids-dir/code/run_mriqc.sh
```

### 3.2 MRIQC and fMRIPrep

Now you can run MRIQC and fMRIPrep on your data using copies of the scripts from `~/bids-dir/code`.

```bash
~/bids-dir/code/run_mriqc.sh 03 ~/bids-dir ~/bids-dir/derivatives/mriqc
~/bids-dir/code/run_fmriprep_min.sh sub-03 ~/bids-dir ~/bids-dir/derivatives/fmriprep
```

#### fMRIPrep Execution in a Loop for Multiple Subjects

You can run the command manually for each subject, but it is usually more efficient to run it in a loop. You can use the same `while` loop pattern shown earlier with `xnat_dcm2bids`, or use GNU Parallel.

Using GNU Parallel requires users to cite the authors in publications.

```bash
while IFS=',' read -r xnatid patient date sub ses _; do
  echo ~/bids-dir/code/run_fmriprep_min.sh "$sub" ~/bids-dir ~/bids-dir/derivatives/fmriprep
done < ~/list.csv
```

```bash
cat ~/list.csv | parallel --colsep ',' --jobs 4 echo ~/bids-dir/code/run_fmriprep_min.sh {4} ~/bids-dir ~/bids-dir/derivatives/fmriprep
```

#### fMRIPrep Output Structure

```text
├── anat
│   ├── sub-XX_space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz
│   │   └─ Normalized T1w image if needed
│   ├── ...
│
├── fmap
│   ├── ...
│
├── func
│   ├── sub-XX_task-cet_desc-confounds_timeseries.tsv
│   │   └─ Confounds to be used in the first-level model
│   ├── ...
│   ├── sub-XX_task-cet_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
│   │   └─ Unsmoothed, preprocessed BOLD time series
│   ├── ...
```

#### Moving from fMRIPrep to SPM

Moving from fMRIPrep to SPM is relatively straightforward. You only need to collect the necessary images and motion regressors.

1. Collect preprocessed images from the fMRIPrep derivatives, for example `*desc-preproc_bold.nii.gz` files. You may need to unzip the files and add smoothing.
2. Collect motion regressors from the fMRIPrep derivatives, for example `*desc-confounds_regressors.tsv` files. Convert them to TXT using our Bash script [extract-confounds-to-spm.sh](https://github.com/nencki-lobi/lobi-mri-scripts/blob/main/fmriprep/extract-confounds-to-spm.sh).
3. Add conditions to your experimental design file and run the model. Remember that SPM templates, although they are in MNI space, are not the same templates used by fMRIPrep. Download the template images from [TemplateFlow](https://templateflow.org/download).

### 3.3 Preinstalled Software

Graphical tools do not work efficiently when launched via `module load` from the Neurodesk repository. Instead, follow these steps to run them locally:

- **MATLAB**: run in Terminal with `./matlab`
- **FSL**: configure it first with `source ~/shared_storage/fsl.sh`, then run `fsleyes`

### 3.4 Loading Software from the Neurodesk Repo

Other programs, including graphical viewers such as Freeview and MRtrix, are not available locally and should be run in Terminal from Neurodesk via `module load XXX` or, more briefly, `ml XXX`, for example `ml ants`.

In Jupyter, the syntax is:

```python
import module
await module.load("ants")
```

You can then run:

```bash
antsRegistration
```

### 3.5 Installing New Software

Use the following commands to install any additional program you need:

```bash
sudo apt update
sudo apt install XXX
```

The software will become unavailable after the environment is shut down.

## FAQ

The FAQ has been moved to [FAQ.md](FAQ.md).
