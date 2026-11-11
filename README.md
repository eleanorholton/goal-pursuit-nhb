
# Goal Pursuit 

Code for reproducing results from the manuscript: ‘Goal commitment is supported by vmPFC through selective attention’ 

This repository contains python and MATLAB code to reproduce the results from both the fMRI study and lesion patient study. The data (behavioural data from both studies and pre-processed fMRI data) are hosted on OSF: https://osf.io/mvquk/files/a34ed. The patient lesion maps are not publicly available as this would compromise the privacy of the research participants.

## Installation

This project includes scripts in both MATLAB and python. 

#### MATLAB (version R2021a)
- MATLAB R2021a can be installed from the official MathWorks website.
- Lesion patient analyses in MATLAB require the fsl toolbox which can be installed here: https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation/FslMatlabConfiguration

#### Jupyter notebooks
The notebooks were written in python3. The dependencies needed to run the python notebooks are listed in the requirements.txt file

#### System
All code was developed and tested on macOS 10.15.6. 

### Data
Data are not stored in this repository. Download them from OSF (https://osf.io/mvquk/files/a34ed) and place the `data/` folder in the root of this repository, so that the scripts can find it:
- Raw and pre-processed behavioral data from the fMRI study, alongside the pre-processed fMRI data, are located in data/mri_study
- Pre-processed behavioural data and voxelwise-regression results can be found in data/lesion_patient_study

### Behavioural pre-processing and modelling
- Navigate to the scripts/mri_study/behaviour directory and open preprocess_data.m to preprocess raw data and add trial-wise value estimates according to the competing behavioural models 

### Main Results and Plots
- Behavioural analyses from the fMRI study can be found in python notebooks in the scripts/mri_study/behaviour directory
- Region of interest (ROI) analyses from the fMRI study can be found in MATLAB files in the scripts/mri_study/neural_fmri directory 
- Behavioural and neural analysis from the patient study can be found in scripts/lesion_patient_study

### License
The code in this repository is released under the MIT License (see LICENSE), with the exception of third-party code listed below.

#### Third-party code
- `scripts/mri_study/neural_fmri/ROI_analyses/helper_scripts/shaded_error_bars/shadedErrorBar.m` was written by Rob Campbell and is distributed via MATLAB Central File Exchange. It is included here for plotting, is not covered by this repository's MIT License, and remains under its original license.

Please email eleanor.r.holton@gmail.com for any questions 