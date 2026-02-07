# CONN Processing Pipeline - Getting Started Checklist

## ✅ Pre-Processing Checklist

### 1. Install CONN (if not already done)
- [ ] Run: `./install_conn_standalone.sh /path/to/install`
- [ ] Load environment: `source ~/.bashrc`
- [ ] Verify: `which conn` (should return path)

### 2. Verify fMRIprep Output
- [ ] fMRIprep directory exists: `/path/to/fmriprep`
- [ ] Contains `sub-001/`, `sub-002/`, etc.
- [ ] Each subject has `anat/` folder with T1w files
- [ ] Each subject has `func/` folder with BOLD files
- [ ] Files include space: `MNI152NLin2009cAsym`
- [ ] Files named like: `*desc-preproc_bold.nii.gz`

### 3. Prepare Workspace
- [ ] Decide on project directory: `/path/to/project`
- [ ] Create directory if needed: `mkdir -p /path/to/project`
- [ ] Ensure you have write permissions
- [ ] Have ~50GB free disk space (for ~50 subjects)

## 📋 Configuration Checklist

### Step 1: Project Setup
File: `batch_conn_01_project_setup.m`

- [ ] Set `PROJECT_DIR` = your project directory
- [ ] Set `NSUBJECTS` = number of subjects in study
- [ ] Set `REPETITION_TIME` = your TR in seconds (e.g., 2.0)
- [ ] Optional: Adjust `VOXEL_RESOLUTION` (usually 1 is fine)
- [ ] Save file

### Step 2: Data Import
File: `batch_conn_02_import_fmriprep.m`

- [ ] Set `PROJECT_DIR` = **same as Step 1**
- [ ] Set `FMRIPREP_DIR` = path to fMRIprep output
- [ ] Verify `BIDS_SPACE` = 'MNI152NLin2009cAsym' (standard)
- [ ] Optional: Set `USE_LOCAL_COPY` = 1 if copying files locally
- [ ] Save file

### Step 3: Smoothing
File: `batch_conn_03_smooth.m`

- [ ] Decide on smoothing FWHM: 4, 6, 8, or 10 mm (8 is standard)
- [ ] Set `VOLUME_SMOOTHING_FWHM` = your choice
- [ ] Keep `VOLUME_SMOOTHING_ENABLED` = true
- [ ] Keep `SURFACE_SMOOTHING_ENABLED` = false (unless doing surface analysis)
- [ ] Save file

### Step 4: Denoising
File: `batch_conn_04_denoise.m`

- [ ] Verify `BANDPASS_LOW` = 0.008 (standard)
- [ ] Verify `BANDPASS_HIGH` = Inf (standard)
- [ ] Verify `DETRENDING_ORDER` = 1 (linear, standard)
- [ ] For standard studies: `USE_STANDARD_CONFOUNDS` = true
- [ ] For high-motion: `USE_STANDARD_CONFOUNDS` = false (adds motion)
- [ ] Keep `GENERATE_QA_PLOTS` = true
- [ ] Save file

## 🚀 Running Checklist

### Option A: Use Master Wrapper (Easiest)

- [ ] Open terminal
- [ ] Navigate: `cd /data/local/software/conn-tools`
- [ ] Load environment: `source ~/.bashrc`
- [ ] Run: `./run_conn_pipeline.sh /path/to/project /path/to/fmriprep`
- [ ] Wait for completion (1-2 hours typical)

### Option B: Run Step-by-Step

- [ ] Open terminal, `cd /data/local/software/conn-tools`
- [ ] Load environment: `source ~/.bashrc`

**Step 1:**
- [ ] Run: `conn batch batch_conn_01_project_setup.m`
- [ ] Wait for completion (~1 min)
- [ ] Check: `conn_project.mat` created in PROJECT_DIR

**Step 2:**
- [ ] Run: `conn batch batch_conn_02_import_fmriprep.m`
- [ ] Wait for completion (~5-10 min)
- [ ] Check: Subjects/functionals imported in log

**Step 3:**
- [ ] Run: `conn batch batch_conn_03_smooth.m`
- [ ] Wait for completion (~10-30 min)
- [ ] Check: Smoothed data in `results/preprocessing/`

**Step 4:**
- [ ] Run: `conn batch batch_conn_04_denoise.m`
- [ ] Wait for completion (~30-60 min)
- [ ] Check: Denoised data in `results/denoising/`

## 🔍 Verification Checklist

After processing completes:

### Check Project Structure
- [ ] `PROJECT_DIR/conn_project.mat` exists
- [ ] `PROJECT_DIR/conn_*/results/` exists
- [ ] `PROJECT_DIR/conn_*/results/preprocessing/` has smoothed data
- [ ] `PROJECT_DIR/conn_*/results/denoising/` has final data ← **USE THIS**

### Check QA Plots
- [ ] `PROJECT_DIR/conn_*/results/qa/` exists
- [ ] Contains `qa_norm_*.png` (registration checks)
- [ ] Contains `qa_denoise_histogram.png` (confound check)
- [ ] Contains `qa_denoise_timeseries.png` (before/after comparison)
- [ ] Contains `qa_denoise_fc_qc.png` (quality metrics)

### Review QA Results
- [ ] Functional data well-aligned to MNI template ✓
- [ ] Denoising histogram shows proper confound removal ✓
- [ ] BOLD timeseries look clean (not noisy) ✓
- [ ] Correlation values reasonable (not extreme) ✓

### Check Log File
- [ ] `PROJECT_DIR/conn_pipeline.log` exists
- [ ] No error messages in log
- [ ] Processing times reasonable (~1-2 hours)

## ⚠️ Common Issues Checklist

### Issue: "CONN not found"
- [ ] Did you run `source ~/.bashrc`?
- [ ] Did you run `install_conn_standalone.sh`?
- [ ] Try: `echo $PATH` (should include CONN dir)

### Issue: "Project not found"
- [ ] Did you run Step 1 first?
- [ ] Did you set correct PROJECT_DIR in all steps?
- [ ] Check: `ls PROJECT_DIR/conn_project.mat`

### Issue: "No subjects found"
- [ ] Check fMRIprep directory path (typo?)
- [ ] Check: `ls FMRIPREP_DIR/sub-*` (should show subjects)
- [ ] Ensure subjects named `sub-001`, `sub-002`, etc.

### Issue: "No functionals found"
- [ ] Check: `ls FMRIPREP_DIR/sub-001/func/*bold.nii.gz`
- [ ] Verify filename includes `MNI152NLin2009cAsym`
- [ ] Try: `find FMRIPREP_DIR -name "*bold.nii.gz"` (should find files)

### Issue: Processing Takes Forever
- [ ] Normal: ~1-2 hours for 50 subjects
- [ ] Check disk space: `df -h`
- [ ] Check if disk is full (would stall processing)
- [ ] Consider reducing NSUBJECTS for testing

### Issue: Out of Disk Space
- [ ] Typical: ~1-2 GB per subject processed
- [ ] Check free space: `df -h`
- [ ] Try: `du -sh PROJECT_DIR/conn_*/` (see current size)
- [ ] Solution: Use `--skip-import` + `USE_LOCAL_COPY=0`

## 📚 Documentation Checklist

Before running, review:
- [ ] `MODULAR_PIPELINE_GUIDE.md` - Comprehensive guide
- [ ] `CONN_QUICK_REFERENCE.md` - Quick configurations
- [ ] `PIPELINE_SUMMARY.md` - Overview
- [ ] Individual script comments (in MATLAB files)

## 🎯 Post-Processing Checklist

Once denoised data is ready:

### Prepare for Analyses
- [ ] Review QA plots and confirm quality
- [ ] Decide on analysis approach:
  - [ ] ROI-to-ROI connectivity (easiest)
  - [ ] Seed-to-Voxel connectivity
  - [ ] Voxel-to-Voxel connectivity
  - [ ] ICA / fc-MVPA / other

### Define ROIs
- [ ] Load standard atlas (AAL, Power, etc.)
  OR
- [ ] Draw custom ROIs
- [ ] Verify ROI placement in MNI space

### Run Connectivity Analyses
- [ ] Define analysis parameters (connectivity measure, weights)
- [ ] Run first-level analysis (within-subject)
- [ ] Extract connectivity matrices
- [ ] Visualize results

### Group-Level Statistics
- [ ] Define between-subjects effects
- [ ] Run second-level analyses
- [ ] Create statistical maps
- [ ] Generate figures for publication

## 📞 Need Help?

### If You Get Stuck
- [ ] Check individual script comments
- [ ] Read relevant section in `MODULAR_PIPELINE_GUIDE.md`
- [ ] Search CONN forum: http://www.nitrc.org/forum/forum.php?forum_id=1144
- [ ] Contact: info@conn-toolbox.org

### Quick Reference
- [ ] CONN docs: https://web.conn-toolbox.org/resources/conn-documentation
- [ ] This repo: `/data/local/software/conn-tools/`
- [ ] fMRIprep: https://fmriprep.org/

---

**Last Updated**: February 2026
**Difficulty**: Beginner to Intermediate
**Time Estimate**: 2-3 hours (including configuration and processing)
