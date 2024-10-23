import argparse
from fsl_mrs.utils import mrs_io
from fsl_mrs.utils import qc
from fsl_mrs.utils.preproc import nifti_mrs_proc as preproc
from fsl_mrs.utils.misc import parse_metab_groups
from fsl_mrs.utils import fitting
import os

# Global variable for the basis file location
basis_location = './slaser30_Mac.basis'

# Function to fit the data and return the result and MRS object
def fit(data, basis_location=basis_location):
    mrs = data.mrs(basis_file=basis_location)
    mrs.check_Basis(repair=True)

    Fitargs = {'ppmlim': (0.2, 5.0),
               'baseline_order': 1,
               'metab_groups': parse_metab_groups(mrs, ['MM09+MM12+MM14+MM17+MM21']),
               'model': 'lorentzian'}

    res = fitting.fit_FSLModel(mrs, **Fitargs)
    return res, mrs

# Function to get the Cr FWHM from the QC result
def get_cr_fwhm(mrs, res):
    mrs_qc = qc.calcQC(mrs, res)
    fwhm_cr = mrs_qc[0].loc[:, 'fwhm_Cr'][0]
    return fwhm_cr

# Apodize function that continues apodization until target FWHM is reached
def apodize(data, target_fwhm_cr, start_fwhm_cr=None):
    if start_fwhm_cr is None:
        res, mrs = fit(data)
        fwhm_cr = get_cr_fwhm(mrs, res)
    else:
        fwhm_cr = start_fwhm_cr

    print(f"FWHM: {fwhm_cr}")

    while fwhm_cr < target_fwhm_cr:
        data = preproc.apodize(data, [0.1])
        res, mrs = fit(data)
        fwhm_cr = get_cr_fwhm(mrs, res)
        print(f"FWHM: {fwhm_cr}")
    
    return data

# Main function to handle command-line arguments and processing
def main():
    # Command-line argument parsing
    parser = argparse.ArgumentParser(description="Apply apodization to FID files.")
    parser.add_argument("files", nargs="+", help="List of FID files to process")
    parser.add_argument("--fwhm_target", type=float, help="Target FWHM for Cr signal")
    parser.add_argument("--basis_location", type=str, default=basis_location, help="Path to the basis file")

    # Parse arguments
    args = parser.parse_args()

    fwhm = []
    data = []
    fwhm_max = 0

    # Load and process each FID file
    for f in args.files:
        f_data = mrs_io.read_FID(f)
        data.append(f_data)

        # Perform initial fitting and FWHM extraction
        res, mrs = fit(f_data)
        fwhm_cr = get_cr_fwhm(mrs, res)
        fwhm.append(fwhm_cr)
        print(f"Initial FWHM for {f}: {fwhm_cr}")

        fwhm_max=max(fwhm_max, fwhm_cr)

    # Apply apodization and save results
    for f, f_data, f_fwhm in zip(args.files, data, fwhm):
        target_fwhm = args.fwhm_target or fwhm_max

        print(f"Apodizing {f} to target FWHM: {target_fwhm}")
        f_data_apodized = apodize(f_data, target_fwhm, f_fwhm)
        
        # Save the apodized FID data (you might need to adjust the save function depending on the data type)
        save_path = os.path.splitext(os.path.splitext(f)[0])[0] + "_apodized.nii.gz"
        f_data_apodized.save(save_path)
        print(f"Apodized data saved to {save_path}")

if __name__ == "__main__":
    main()
