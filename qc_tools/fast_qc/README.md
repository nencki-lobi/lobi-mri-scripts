# FastQC

Fast MRI quality control using [SynthSeg](https://surfer.nmr.mgh.harvard.edu/fswiki/SynthSeg) for segmentation and [niimath](https://github.com/rordenlab/niimath) for QC metrics.

The `--air` option registers a reference template to the input image and enables additional air/background-based metrics, including Dietrich SNR, FBER, QI1, background statistics, and full CNR.

The QC metrics are inspired by MRIQC, but this pipeline is not MRIQC and the results should not be expected to exactly match MRIQC outputs.

## Usage

```bash
~/FastQC/run_qc.sh t1.nii result.json
```

The output QC metrics are saved to `result.json`.
