# CONN Processing Pipeline Summary

**Location**: `/data/local/software/conn-tools/`

Complete modular pipeline for fMRI preprocessing and connectivity analysis.

## 📦 What's New (February 2026)

### New Modular Scripts
4 separate, independent MATLAB batch scripts:
- ✅ `batch_conn_01_project_setup.m` - Create CONN project
- ✅ `batch_conn_02_import_fmriprep.m` - Import fMRIprep data
- ✅ `batch_conn_03_smooth.m` - Apply smoothing
- ✅ `batch_conn_04_denoise.m` - Denoising (final preprocessing)

### Master Wrapper
- ✅ `run_conn_pipeline.sh` - Automated master script (runs all 4 steps)

### Documentation
- ✅ `MODULAR_PIPELINE_GUIDE.md` - Comprehensive guide (100+ sections)
- ✅ `CONN_QUICK_REFERENCE.md` - Quick reference card
- ✅ `PIPELINE_SUMMARY.md` - This file

## 🚀 Quick Start

```bash
# 1. Load CONN environment
source ~/.bashrc

# 2. Edit Step 1 config
vim batch_conn_01_project_setup.m
# Change: PROJECT_DIR, NSUBJECTS, REPETITION_TIME

# 3. Run entire pipeline (automatically runs all 4 steps)
./run_conn_pipeline.sh /project/directory /fmriprep/directory

# 4. Review output
ls /project/directory/conn_*/results/qa/
```

## 📊 Pipeline Overview

```
Step 1: Project Setup
├── Initialize CONN project
├── Set TR, voxel resolution
└── Configure analysis types

       ↓

Step 2: Import fMRIprep Data
├── Auto-discover subjects in fMRIprep
├── Import structurals (T1w in MNI)
├── Import functionals (BOLD in MNI)
└── Support multi-session studies

       ↓

Step 3: Spatial Smoothing
├── Volume-based: 4, 6, 8, 10 mm FWHM
├── OR Surface-based: diffusion steps
└── Output: Smoothed data

       ↓

Step 4: Denoising
├── Confound regression (WM, CSF, motion)
├── Band-pass filtering (0.008 Hz default)
├── Temporal detrending
├── Generate QA plots
└── Output: Final denoised BOLD data ✓

       ↓

Ready for Connectivity Analysis
├── Define ROIs
├── ROI-to-ROI connectivity
├── Seed-to-Voxel connectivity
├── Voxel-to-Voxel connectivity
└── Group-level statistics
```

## 📁 File Locations

```
/data/local/software/conn-tools/
├── Scripts (4 main)
│   ├── batch_conn_01_project_setup.m
│   ├── batch_conn_02_import_fmriprep.m
│   ├── batch_conn_03_smooth.m
│   └── batch_conn_04_denoise.m
│
├── Wrapper
│   └── run_conn_pipeline.sh
│
├── Documentation
│   ├── MODULAR_PIPELINE_GUIDE.md (detailed)
│   ├── CONN_QUICK_REFERENCE.md (quick lookup)
│   ├── PIPELINE_SUMMARY.md (this file)
│   └── INSTALL_CONN_STANDALONE.md (installation)
│
└── Original Tools (GUI, etc.)
    ├── app.py
    ├── scripts_py/
    ├── templates/
    └── (other original files)
```

## 🎯 Why Modular?

| Feature | Old | New |
|---------|-----|-----|
| Single script runs all | ✓ | Limited |
| Run subset of steps | ✗ | ✓ |
| Re-run single step | ✗ | ✓ |
| Debug individual steps | ✗ | ✓ |
| Customize per step | Limited | ✓ |
| Error recovery | Start over | Skip to failed step |

## ⚙️ Configuration

### Step 1: Project Setup
```matlab
PROJECT_DIR = '/path/to/project';     % Where to save
NSUBJECTS = 30;                        % Number of subjects
REPETITION_TIME = 2.0;                 % Your TR in seconds
```

### Step 2: Import fMRIprep
```matlab
PROJECT_DIR = '/path/to/project';      % Must match Step 1
FMRIPREP_DIR = '/path/to/fmriprep';   % fMRIprep output
BIDS_SPACE = 'MNI152NLin2009cAsym';   % Standard (don't change)
```

### Step 3: Smoothing
```matlab
VOLUME_SMOOTHING_ENABLED = true;
VOLUME_SMOOTHING_FWHM = 8;             % 4, 6, 8, or 10 mm
```

### Step 4: Denoising
```matlab
BANDPASS_LOW = 0.008;                  % Hz
BANDPASS_HIGH = Inf;                   % Hz
DETRENDING_ORDER = 1;                  % 0, 1, 2, or 3
USE_STANDARD_CONFOUNDS = true;         % WM + CSF
GENERATE_QA_PLOTS = true;              % Create plots
```

## 🖥️ Running Options

### Option 1: Master Wrapper (Recommended)
```bash
./run_conn_pipeline.sh /project /fmriprep
./run_conn_pipeline.sh /project /fmriprep --fwhm 6
./run_conn_pipeline.sh /project /fmriprep --skip-smooth
```

### Option 2: Step-by-Step
```bash
conn batch batch_conn_01_project_setup.m
conn batch batch_conn_02_import_fmriprep.m
conn batch batch_conn_03_smooth.m
conn batch batch_conn_04_denoise.m
```

### Option 3: From MATLAB
```matlab
cd /data/local/software/conn-tools
batch_conn_01_project_setup
batch_conn_02_import_fmriprep
batch_conn_03_smooth
batch_conn_04_denoise
```

## 📈 Typical Runtime

- Step 1 (Setup): ~1 minute
- Step 2 (Import): ~5-10 minutes (depends on number of subjects)
- Step 3 (Smoothing): ~10-30 minutes
- Step 4 (Denoising): ~30-60 minutes

**Total**: 1-2 hours for typical 50-subject study

## ✅ Quality Assurance

After Step 4, check `results/qa/` for:
1. **Mean functional alignment** - Register to MNI?
2. **Denoising histogram** - Proper confound modeling?
3. **BOLD timeseries** - Artifacts or noise?
4. **FC-QC metrics** - Quality control?

## 📚 Documentation Files

| File | Contents | For Whom |
|------|----------|----------|
| `MODULAR_PIPELINE_GUIDE.md` | Complete 100+ section guide | Everyone doing analysis |
| `CONN_QUICK_REFERENCE.md` | Configurations, examples, tips | Quick lookup |
| `INSTALL_CONN_STANDALONE.md` | Installation guide | First-time users |
| `PIPELINE_SUMMARY.md` | This file (overview) | Quick overview |

## 🔧 Common Tasks

### Re-run denoising with different parameters
```bash
# Edit batch_conn_04_denoise.m, then:
./run_conn_pipeline.sh /proj /fmriprep --skip-setup --skip-import --skip-smooth
```

### Try different smoothing
```bash
# Run with 6mm instead of 8mm
./run_conn_pipeline.sh /proj /fmriprep --fwhm 6
```

### Process multiple studies
```bash
for study in study1 study2 study3; do
  ./run_conn_pipeline.sh /data/$study /fmriprep
done
```

### Skip smoothing for surface-based analysis
```bash
# Edit batch_conn_03_smooth.m to disable volume smoothing, then:
./run_conn_pipeline.sh /proj /fmriprep
```

## 🆘 Troubleshooting

**"CONN not found"**
```bash
source ~/.bashrc  # Load CONN environment
```

**"No subjects found"**
- Check FMRIPREP_DIR is correct
- Verify subjects are named `sub-001`, `sub-002`, etc.

**"No functionals found"**
- Check fMRIprep includes `*space-MNI152NLin2009cAsym*bold.nii.gz`
- Verify `BIDS_SPACE` setting

**"Smoothing failed"**
- Verify data was imported successfully (Step 2)
- Check disk space

## 🎓 Workflow Example: Start to Finish

```bash
# 1. Install CONN (one-time)
./install_conn_standalone.sh ~/conn
source ~/.bashrc

# 2. Prepare your fMRIprep output
# (Already preprocessed with fMRIprep)

# 3. Edit project settings
vim batch_conn_01_project_setup.m
# Set: PROJECT_DIR, NSUBJECTS=50, REPETITION_TIME=2.0

# 4. Edit import settings
vim batch_conn_02_import_fmriprep.m
# Set: FMRIPREP_DIR=/path/to/fmriprep

# 5. Run pipeline (all 4 steps)
./run_conn_pipeline.sh /myproject /fmriprep

# 6. Check quality
open /myproject/conn_*/results/qa/

# 7. Now ready for connectivity analysis!
# Define ROIs, run first/second-level analyses, etc.
```

## 📞 Support

- **CONN**: https://web.conn-toolbox.org/
- **Forum**: http://www.nitrc.org/forum/forum.php?forum_id=1144
- **fMRIprep**: https://fmriprep.org/
- **Email**: info@conn-toolbox.org

---

**Created**: February 2026  
**Version**: 2.0 (Modular)  
**Location**: `/data/local/software/conn-tools/`
