# CONN Batch Script: fMRIprep Data Import, Smoothing, and Denoising

## Overview

This script automates the import of fMRIprep preprocessed fMRI data into CONN, applies spatial smoothing, and performs denoising (confound removal and band-pass filtering).

## Prerequisites

- **fMRIprep** preprocessed data in standard MNI space
- **CONN** standalone or MATLAB installation
- Data directory structure following BIDS format (or fMRIprep standard output)

## Script Location

```
batch_fmriprep_import_smooth_denoise.m
```

## Configuration

### 1. Edit User Settings

Open the script and modify the configuration section at the top:

```matlab
% Project configuration
PROJECT_NAME        = 'fMRIprep_Analysis';          
PROJECT_DIR         = '/path/to/project/directory'; 
FMRIPREP_DIR        = '/path/to/fmriprep/dataset';  

% Smoothing parameters
SMOOTHING_FWHM      = 8;      % 8mm is standard; adjust as needed

% Denoising parameters
BANDPASS_LOW        = 0.008;  % Low-frequency cutoff (Hz)
BANDPASS_HIGH       = Inf;    % High-frequency cutoff (Hz)
DETRENDING_ORDER    = 1;      % 0=none, 1=linear (recommended)
```

### 2. Key Parameters Explained

| Parameter | Default | Description |
|-----------|---------|-------------|
| `PROJECT_DIR` | User-defined | Where CONN project files will be saved |
| `FMRIPREP_DIR` | User-defined | Root directory of fMRIprep output |
| `SMOOTHING_FWHM` | 8 | Spatial smoothing kernel in mm (Full Width Half Maximum) |
| `BANDPASS_LOW` | 0.008 | Low-frequency cutoff (Hz); 0.008 Hz = 125 sec period |
| `BANDPASS_HIGH` | Inf | High-frequency cutoff; Inf means no filtering |
| `DETRENDING_ORDER` | 1 | 0=none, 1=linear, 2=quadratic, 3=cubic |
| `MOTION_REGRESSORS` | true | Include motion parameters in denoising |
| `SCRUBBING` | true | Flag high-motion frames |
| `GENERATE_QA_PLOTS` | true | Create quality assurance visualizations |

## Expected fMRIprep Directory Structure

```
fmriprep/
├── sub-001/
│   ├── anat/
│   │   ├── sub-001_space-MNI152NLin2009cAsym_T1w.nii.gz
│   │   └── ... (other anatomical files)
│   └── func/
│       ├── sub-001_task-rest_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
│       ├── sub-001_task-rest_space-MNI152NLin2009cAsym_desc-preproc_bold.json
│       └── ... (other functional files)
├── sub-002/
│   └── ...
└── ...
```

The script automatically discovers and imports:
- **Structurals**: T1w images in MNI space
- **Functionals**: Preprocessed BOLD images (space-MNI152NLin2009cAsym)

## Running the Script

### Option 1: From MATLAB/Octave

```matlab
% Navigate to script directory or add to path
cd /data/local/software/conn-tools

% Run the script
batch_fmriprep_import_smooth_denoise
```

### Option 2: From Command Line (Standalone CONN)

```bash
# Make sure CONN environment is loaded
source ~/.bashrc

# Run using CONN batch command
conn batch batch_fmriprep_import_smooth_denoise.m
```

### Option 3: From Python (optional wrapper)

Create a wrapper script to call the MATLAB script:

```bash
#!/bin/bash
cd /data/local/software/conn-tools
source ~/.bashrc
conn batch batch_fmriprep_import_smooth_denoise.m 2>&1 | tee conn_processing.log
```

## Processing Steps

The script performs the following steps sequentially:

1. **Data Discovery**: Automatically scans FMRIPREP_DIR for subjects and files
2. **Project Setup**: Creates new CONN project and imports structural/functional data
3. **Smoothing**: Applies spatial Gaussian smoothing (if SMOOTHING_FWHM > 0)
4. **Denoising**:
   - Removes confounds (White Matter, CSF, motion)
   - Band-pass filtering
   - Temporal detrending
5. **Quality Assurance**: Generates QA plots to assess preprocessing

## Output

After successful execution, you'll find:

```
PROJECT_DIR/
├── conn_project.mat              # CONN project file
├── conn_*/
│   ├── data/                     # Raw data copies (optional)
│   ├── working/                  # Processing working directory
│   ├── results/
│   │   ├── preprocessing/        # Smoothed data
│   │   ├── denoising/            # Denoised data
│   │   └── qa/                   # QA plots
│   └── ...
└── (additional CONN project files)
```

### Key Output Files

- **Denoised BOLD**: `resultstemplate/preprocessing/ROI_denoised/*_bold.nii`
- **QA Plots**: `results/qa/` - Review these to assess data quality
- **Processing Report**: Check MATLAB console output

## Confound Modeling

The script regresses out standard confounds:

**Default Confounds:**
- White Matter signal
- Cerebrospinal Fluid (CSF) signal

**Optional Additions** (uncomment in script):
- Motion regressors (realignment parameters)
- Realignment derivatives
- Quadratic and power terms

### Recommended Confound Sets

| Use Case | Confounds |
|----------|-----------|
| Standard connectivity | WM, CSF |
| With motion censoring | WM, CSF, motion, outlier flags |
| Conservative denoising | WM, CSF, motion, motion derivatives |

## Denoising Strategies

### Strategy 1: Standard (Recommended)
```matlab
BANDPASS_LOW = 0.008;        % 0.008 - Inf Hz
BANDPASS_HIGH = Inf;
CONFOUNDS = {'White Matter', 'CSF'};
REGBP_ORDER = 1;             % Regression then bandpass (RegBP)
```

### Strategy 2: Aggressive Denoising
```matlab
BANDPASS_LOW = 0.01;
BANDPASS_HIGH = 0.1;
CONFOUNDS = {'White Matter', 'CSF', ...};  % Add motion
DETRENDING_ORDER = 2;        % Quadratic detrending
```

### Strategy 3: Minimal Denoising
```matlab
BANDPASS_LOW = 0.008;
BANDPASS_HIGH = Inf;
CONFOUNDS = {};              % No confounds
```

## Troubleshooting

### Problem: "No subject directories found"
- Verify FMRIPREP_DIR path is correct
- Ensure subject folders are named `sub-XXX` (BIDS format)
- Check file permissions

### Problem: "No functional files found"
- Verify fMRIprep output includes `*space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz`
- Check space parameter is correct (script looks for MNI152NLin2009cAsym)

### Problem: CONN project creation fails
- Verify PROJECT_DIR exists and is writable
- Check that CONN is properly installed and in PATH
- Try creating PROJECT_DIR manually first

### Problem: "RT not specified"
- Edit script to set explicit TR value: `BATCH.Setup.RT = 2.0;` (adjust to your TR)
- Or ensure .json sidecars exist in fMRIprep output

## Advanced Customization

### Adding ROIs for Extraction

Uncomment and modify in the script:

```matlab
BATCH.Setup.rois.files = {'~/roi_atlas.nii.gz'};
BATCH.Setup.rois.names = {'Atlas'};
```

### Parallel Processing (HPC/Cluster)

Modify the Setup section:

```matlab
BATCH.parallel.N = 10;              % Use 10 parallel nodes
BATCH.parallel.profile = 'slurm';   % Or 'sge', 'pbs', etc.
```

### Session-specific Processing

The script automatically handles multiple sessions:

```
sub-001/
├── ses-01/
│   ├── anat/
│   └── func/
├── ses-02/
│   ├── anat/
│   └── func/
```

## Quality Assurance

The script generates these QA plots:

1. **Mean functional + MNI template** - Verify registration
2. **Denoising histogram** - Check confound modeling
3. **BOLD timeseries** - Visual inspection before/after
4. **FC-QC associations** - Quality control metrics

Review `results/qa/` after processing completes.

## Next Steps After Processing

1. **Review QA plots** - Check registration and denoising quality
2. **Define ROIs** - Import atlas or draw custom ROIs
3. **First-level analysis** - ROI-to-ROI, seed-to-voxel, voxel-to-voxel connectivity
4. **Second-level analysis** - Group-level statistics

## References

- [CONN Documentation](https://web.conn-toolbox.org/resources/conn-documentation)
- [fMRIprep Documentation](https://fmriprep.org/)
- [CONN fMRI Methods](https://web.conn-toolbox.org/fmri-methods)
- [CONN Batch Functions](https://web.conn-toolbox.org/resources/conn-documentation/conn_batch)

## Support

For issues:
- Check CONN forum: http://www.nitrc.org/forum/forum.php?forum_id=1144
- Contact: info@conn-toolbox.org
