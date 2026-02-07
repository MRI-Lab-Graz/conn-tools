# CONN Modular Processing Pipeline

A complete, step-by-step pipeline for processing fMRI data in CONN with separated concerns.

## Overview

The pipeline is divided into 4 independent but sequential scripts:

1. **Step 1: Project Setup** (`batch_conn_01_project_setup.m`)
   - Create new CONN project
   - Configure basic parameters (TR, voxel resolution, etc.)

2. **Step 2: Data Import** (`batch_conn_02_import_fmriprep.m`)
   - Import fMRIprep preprocessed data
   - Auto-discover subjects and files
   - Support for single/multi-session studies

3. **Step 3: Smoothing** (`batch_conn_03_smooth.m`)
   - Apply spatial smoothing (volume or surface)
   - Configurable FWHM (4, 6, 8, 10 mm)
   - Optional: Skip if already smoothed

4. **Step 4: Denoising** (`batch_conn_04_denoise.m`)
   - Confound regression (WM, CSF, motion)
   - Band-pass filtering
   - Temporal detrending
   - Quality assurance plots

## Quick Start

### Option A: Run Each Step Individually

```bash
# Step 1: Setup
cd /data/local/software/conn-tools
source ~/.bashrc
conn batch batch_conn_01_project_setup.m

# Step 2: Import
conn batch batch_conn_02_import_fmriprep.m

# Step 3: Smooth
conn batch batch_conn_03_smooth.m

# Step 4: Denoise
conn batch batch_conn_04_denoise.m
```

### Option B: Run All Steps at Once

```bash
./run_conn_pipeline.sh /project/dir /fmriprep/dir
```

### Option C: Run from MATLAB

```matlab
% Edit paths in each script, then run in sequence:
batch_conn_01_project_setup
batch_conn_02_import_fmriprep
batch_conn_03_smooth
batch_conn_04_denoise
```

## Detailed Configuration

### Step 1: Project Setup

**File:** `batch_conn_01_project_setup.m`

```matlab
PROJECT_NAME        = 'My_fMRI_Project';
PROJECT_DIR         = '/path/to/project/directory';
NSUBJECTS           = 30;
REPETITION_TIME     = 2.0;  % Your TR in seconds

VOXEL_RESOLUTION    = 1;    % 1: 2mm MNI (default)
                            % 2: Same as structurals
                            % 3: Same as functionals
                            % 4: Surface-based
```

### Step 2: Data Import (fMRIprep)

**File:** `batch_conn_02_import_fmriprep.m`

```matlab
PROJECT_DIR     = '/path/to/project/directory';  % Must match Step 1
FMRIPREP_DIR    = '/path/to/fmriprep/dataset';
BIDS_SPACE      = 'MNI152NLin2009cAsym';  % Standard fMRIprep output
USE_LOCAL_COPY  = 0;  % 0: Use original files (faster)
                      % 1: Copy to project (slower, more disk space)
```

**Expected fMRIprep Structure:**
```
fmriprep/
├── sub-001/
│   ├── anat/
│   │   └── *space-MNI152NLin2009cAsym*T1w.nii.gz
│   └── func/
│       └── *space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz
├── sub-002/
└── ...
```

### Step 3: Smoothing

**File:** `batch_conn_03_smooth.m`

```matlab
% Volume-based smoothing (standard)
VOLUME_SMOOTHING_ENABLED = true;
VOLUME_SMOOTHING_FWHM    = 8;  % mm (4, 6, 8, 10 typical)

% Surface-based smoothing (alternative)
SURFACE_SMOOTHING_ENABLED = false;
SURFACE_SMOOTHING_STEPS   = 5;  % Diffusion steps

% Set one to true, the other to false
```

**FWHM Recommendations:**
- **4-6 mm**: High spatial detail, more noise
- **8 mm**: Standard (good balance)
- **10 mm**: Smoother, more statistical power, less detail

### Step 4: Denoising

**File:** `batch_conn_04_denoise.m`

```matlab
% Band-pass filtering
BANDPASS_LOW    = 0.008;  % Hz (0.008 = 125 sec period)
BANDPASS_HIGH   = Inf;    % Hz (Inf = no high-pass filtering)

% Detrending
DETRENDING_ORDER = 1;     % 0=none, 1=linear, 2=quadratic

% Despiking
DESPIKING_ENABLED = false;  % Usually not needed for fMRIprep

% Confounds
USE_STANDARD_CONFOUNDS = true;  % true: WM + CSF
                                % false: WM + CSF + motion params
INCLUDE_MOTION_DERIVATIVES = false;
```

**Confound Regression Options:**

| Preset | Confounds | Best For |
|--------|-----------|----------|
| Standard | WM, CSF | Most studies (recommended) |
| With Motion | WM, CSF, Realignment | If motion is a concern |
| Aggressive | WM, CSF, Motion + Derivatives | High-motion studies |
| Minimal | (none) | Testing/validation only |

**Recommended Settings by Study Type:**

### Default/Standard (recommended)
```matlab
USE_STANDARD_CONFOUNDS = true;
BANDPASS_LOW = 0.008;
BANDPASS_HIGH = Inf;
DETRENDING_ORDER = 1;
INCLUDE_MOTION_DERIVATIVES = false;
```

### Motion-Heavy (pediatric, clinical)
```matlab
USE_STANDARD_CONFOUNDS = false;  % Includes motion
BANDPASS_LOW = 0.008;
BANDPASS_HIGH = Inf;
DETRENDING_ORDER = 1;
INCLUDE_MOTION_DERIVATIVES = true;
```

### Conservative (very strict)
```matlab
USE_STANDARD_CONFOUNDS = false;  % Includes motion
BANDPASS_LOW = 0.01;
BANDPASS_HIGH = 0.1;  % Limited band-pass
DETRENDING_ORDER = 2;  % Quadratic
INCLUDE_MOTION_DERIVATIVES = true;
```

## Data Organization Recommendations

```
project/
├── fmriprep/          # Original preprocessed data (read-only)
├── conn_project/      # CONN working directory (Step 1 output)
│   ├── conn_project.mat
│   ├── conn_*/
│   │   ├── data/
│   │   ├── results/
│   │   │   ├── preprocessing/    # From Step 3
│   │   │   ├── denoising/        # From Step 4 (FINAL DATA)
│   │   │   └── qa/               # Quality assurance plots
│   │   └── ...
│   └── processing.log             # Log file
└── analyses/          # For first/second-level analyses (later steps)
```

## Quality Assurance

After Step 4 (Denoising), review:

1. **Registration QA**: Check structural/functional alignment to MNI template
2. **Denoising Histogram**: Verify confound modeling worked
3. **BOLD Timeseries**: Visual inspection before/after denoising
4. **FC-QC Plot**: Quality control metrics

**Location:** `PROJECT_DIR/results/qa/`

Common issues to look for:
- ❌ Poor registration → Recheck fMRIprep output
- ❌ Extreme FC values → May need different denoising parameters
- ❌ Insufficient motion scrubbing → Consider stricter confounds
- ✅ Smooth BOLD signal → Good!
- ✅ Reasonable correlation values → Good!

## Troubleshooting

### Project file not found
```
Error: Project file not found
Solution: Run batch_conn_01_project_setup.m first
```

### No subjects found
```
Error: No subject directories (sub-*) found
Solution: Check FMRIPREP_DIR path; ensure sub-* naming
```

### No functional files found
```
Error: No functional files found
Solution: 
  - Check fMRIprep output includes space-MNI152NLin2009cAsym files
  - Verify BIDS_SPACE setting in script
  - Check file naming: *desc-preproc_bold.nii.gz
```

### Smoothing failed
```
Error during smoothing
Solution: Verify data was properly imported in Step 2
          Check disk space and permissions
```

### Denoising failed
```
Error during denoising
Solution: Check that confound names match CONN conventions
          Verify confounds exist in project (WM, CSF defined)
```

## Advanced: Custom Configurations

### Example 1: No Smoothing
```matlab
% Step 3: batch_conn_03_smooth.m
VOLUME_SMOOTHING_ENABLED = false;
SURFACE_SMOOTHING_ENABLED = false;
% Script will exit without applying smoothing
```

### Example 2: Surface-Based Analysis
```matlab
% Step 1: batch_conn_01_project_setup.m
VOXEL_RESOLUTION = 4;  % Surface-based

% Step 3: batch_conn_03_smooth.m
SURFACE_SMOOTHING_ENABLED = true;
SURFACE_SMOOTHING_STEPS = 10;
```

### Example 3: Very Strict Quality Control
```matlab
% Step 4: batch_conn_04_denoise.m
USE_STANDARD_CONFOUNDS = false;          % Motion included
INCLUDE_MOTION_DERIVATIVES = true;        % Full motion model
BANDPASS_LOW = 0.01;
BANDPASS_HIGH = 0.1;
DETRENDING_ORDER = 2;
SCRUBBING_ENABLED = true;
```

## Output Files

After complete pipeline:

```
PROJECT_DIR/
├── conn_project.mat                          # Main project file
├── conn_*/
│   └── results/
│       ├── preprocessing/                    # Step 3 output
│       │   └── (smoothed volumes)
│       ├── denoising/                        # Step 4 output (MAIN DATA)
│       │   ├── BOLD_<step>_*_bold.nii       # Denoised BOLD
│       │   └── ...
│       └── qa/                               # Quality assurance
│           ├── qa_denoise_histogram.png
│           ├── qa_denoise_timeseries.png
│           └── ...
└── processing.log
```

## Next: First-Level Analyses

With denoised data ready, you can now:

1. **Define ROIs**
   - Import standard atlases (AAL, Power, etc.)
   - Draw custom ROIs
   - Extract timeseries

2. **Run Connectivity Analyses**
   - ROI-to-ROI functional connectivity
   - Seed-to-Voxel connectivity maps
   - Voxel-to-Voxel connectivity

3. **Run Group-Level Analyses**
   - Between-subject effects
   - Between-condition effects
   - Covariates and group comparisons

4. **Visualize Results**
   - Network plots
   - Statistical maps
   - Connectivity matrices

## References

- [CONN Documentation](https://web.conn-toolbox.org/resources/conn-documentation)
- [conn_batch Help](https://web.conn-toolbox.org/resources/conn-documentation/conn_batch)
- [fMRIprep Documentation](https://fmriprep.org/)
- [CONN fMRI Methods](https://web.conn-toolbox.org/fmri-methods)

## Support

- CONN Forum: http://www.nitrc.org/forum/forum.php?forum_id=1144
- Contact: info@conn-toolbox.org
