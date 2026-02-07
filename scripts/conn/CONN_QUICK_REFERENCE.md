# CONN Modular Pipeline - Quick Reference

## Files Created

```
batch_conn_01_project_setup.m          Step 1: Create & configure CONN project
batch_conn_02_import_fmriprep.m        Step 2: Import fMRIprep data
batch_conn_03_smooth.m                 Step 3: Apply spatial smoothing
batch_conn_04_denoise.m                Step 4: Denoising (confounds + filtering)

run_conn_pipeline.sh                   Master wrapper (runs all 4 steps)
MODULAR_PIPELINE_GUIDE.md              Detailed documentation
CONN_QUICK_REFERENCE.md                This file
```

## Running the Pipeline

### Easiest: Use Master Script
```bash
cd /data/local/software/conn-tools
source ~/.bashrc
./run_conn_pipeline.sh /project/dir /fmriprep/dir
```

### Step-by-Step: Run Each Individually
```bash
# Edit paths in each script, then:
conn batch batch_conn_01_project_setup.m
conn batch batch_conn_02_import_fmriprep.m
conn batch batch_conn_03_smooth.m
conn batch batch_conn_04_denoise.m
```

### From MATLAB
```matlab
cd /data/local/software/conn-tools
batch_conn_01_project_setup
batch_conn_02_import_fmriprep
batch_conn_03_smooth
batch_conn_04_denoise
```

## Configuration at a Glance

### Step 1: Project Setup
Edit `batch_conn_01_project_setup.m`:
```matlab
PROJECT_DIR    = '/path/to/project';
NSUBJECTS      = 30;
REPETITION_TIME = 2.0;  % Your TR
```

### Step 2: fMRIprep Import
Edit `batch_conn_02_import_fmriprep.m`:
```matlab
PROJECT_DIR   = '/path/to/project';  % Must match Step 1
FMRIPREP_DIR  = '/path/to/fmriprep';
BIDS_SPACE    = 'MNI152NLin2009cAsym';  % Standard
```

### Step 3: Smoothing
Edit `batch_conn_03_smooth.m`:
```matlab
VOLUME_SMOOTHING_ENABLED = true;
VOLUME_SMOOTHING_FWHM    = 8;  % 4, 6, 8, 10 mm typical
```

### Step 4: Denoising
Edit `batch_conn_04_denoise.m`:
```matlab
BANDPASS_LOW        = 0.008;  % Hz
BANDPASS_HIGH       = Inf;    % Hz
DETRENDING_ORDER    = 1;      % 0, 1, 2, 3
USE_STANDARD_CONFOUNDS = true;  % true: WM+CSF only
GENERATE_QA_PLOTS   = true;
```

## Master Script Options

```bash
./run_conn_pipeline.sh <project_dir> <fmriprep_dir> [options]

Options:
  --skip-setup      Skip project creation (already exists)
  --skip-import     Skip data import
  --skip-smooth     Skip smoothing
  --skip-denoise    Skip denoising
  --fwhm <mm>       Set smoothing FWHM
  --no-qa           Skip QA plots
```

Examples:
```bash
# Default: All steps, 8mm smoothing, with QA
./run_conn_pipeline.sh /proj /fmriprep

# Skip smoothing, 6mm if needed, no QA
./run_conn_pipeline.sh /proj /fmriprep --skip-smooth --no-qa

# Re-run denoising only (skip first 3 steps)
./run_conn_pipeline.sh /proj /fmriprep --skip-setup --skip-import --skip-smooth
```

## Output Locations

```
PROJECT_DIR/
├── conn_project.mat                    # Main project file
├── conn_*/
│   ├── data/                           # Raw data (if copied)
│   └── results/
│       ├── preprocessing/              # Step 3 output
│       ├── denoising/                  # Step 4 output ← FINAL DATA
│       └── qa/                         # Quality assurance plots
└── conn_pipeline.log                   # Processing log
```

## Common Configurations

### Standard (Recommended)
- Smoothing: 8mm FWHM
- Confounds: WM + CSF
- Bandpass: 0.008 Hz (no high-pass)
- Detrending: Linear (order=1)

### Pediatric/High-Motion
- Smoothing: 8-10mm FWHM
- Confounds: WM + CSF + Motion + Derivatives
- Bandpass: 0.008 Hz
- Detrending: Linear (order=1)

### Conservative/Strict
- Smoothing: 6-8mm FWHM
- Confounds: WM + CSF + Motion + Derivatives
- Bandpass: 0.01-0.1 Hz
- Detrending: Quadratic (order=2)

### Minimal Processing
- Smoothing: 0 (disabled)
- Confounds: WM + CSF only
- Bandpass: 0.008 Hz
- Detrending: Linear (order=1)

## Troubleshooting

| Error | Cause | Solution |
|-------|-------|----------|
| Project not found | Step 1 not run | Run batch_conn_01 first |
| No subjects found | Wrong path or naming | Check FMRIPREP_DIR, ensure sub-* folders |
| No functionals found | Wrong space/naming | Verify fMRIprep includes MNI files |
| Smoothing failed | Bad data import | Check Step 2 completed successfully |
| Denoising failed | Missing confounds | Verify WM/CSF masks exist |

## QA Plots to Review

After Step 4, check `results/qa/` for:
1. **Mean functional** - Verify MNI registration
2. **Denoising histogram** - Check confound modeling
3. **BOLD timeseries** - Visual before/after
4. **FC-QC** - Quality control metrics

Red flags:
- ❌ Misalignment to MNI
- ❌ Extreme connectivity values
- ❌ Artifacts in timeseries
- ❌ Poor correlation structure

## Next: First-Level Analysis

Once denoising is complete:

1. **Define ROIs**
   - Load standard atlas (AAL, Power, etc.)
   - Or draw custom ROIs

2. **Extract Timeseries**
   - ROI-level BOLD signals

3. **Compute Connectivity**
   - ROI-to-ROI correlations
   - Seed-to-voxel maps
   - Full voxel-to-voxel

4. **Statistics**
   - Group-level analyses
   - Covariates
   - Contrasts

## Tips & Tricks

**Speed up by skipping unnecessary steps:**
```bash
# Re-run denoising with different parameters
./run_conn_pipeline.sh /proj /fmriprep --skip-setup --skip-import --skip-smooth
```

**Try different smoothing:**
```bash
# Run with 6mm instead of default 8mm
./run_conn_pipeline.sh /proj /fmriprep --fwhm 6
```

**Batch processing multiple projects:**
```bash
for proj in project1 project2 project3; do
  ./run_conn_pipeline.sh /data/$proj /fmriprep
done
```

## Key Differences from Old Script

| Feature | Old | New |
|---------|-----|-----|
| Modularity | Single script | 4 separate scripts |
| Flexibility | Run all or nothing | Run any subset |
| Configuration | Hidden in code | Clear user section |
| Reusability | Limited | High (step by step) |
| Error recovery | Restart from beginning | Restart at failed step |
| Testing | Hard to test parts | Easy to iterate |

## References

- Full documentation: `MODULAR_PIPELINE_GUIDE.md`
- CONN docs: https://web.conn-toolbox.org/resources/conn-documentation
- fMRIprep docs: https://fmriprep.org/

## Support

- CONN forum: http://www.nitrc.org/forum/forum.php?forum_id=1144
- Email: info@conn-toolbox.org
