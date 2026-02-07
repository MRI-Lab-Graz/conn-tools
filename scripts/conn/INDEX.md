# CONN Tools - Complete Index

**Directory**: `/data/local/software/conn-tools/`

Complete modular pipeline for fMRI preprocessing with CONN.

---

## 🎯 START HERE

### For First-Time Users
1. Read: [GETTING_STARTED.md](GETTING_STARTED.md) - Step-by-step checklist
2. Read: [INSTALL_CONN_STANDALONE.md](INSTALL_CONN_STANDALONE.md) - Install CONN if needed
3. Read: [PIPELINE_SUMMARY.md](PIPELINE_SUMMARY.md) - 5-minute overview

### For Experienced Users
- [CONN_QUICK_REFERENCE.md](CONN_QUICK_REFERENCE.md) - Configurations and examples
- Individual script comments (in .m files)

### For Detailed Documentation
- [MODULAR_PIPELINE_GUIDE.md](MODULAR_PIPELINE_GUIDE.md) - 100+ section comprehensive guide

---

## 📦 Scripts

### Main Processing Pipeline (4 Steps)

```
Step 1: Project Setup
└─ batch_conn_01_project_setup.m
   Create and configure CONN project

Step 2: Data Import (fMRIprep)
└─ batch_conn_02_import_fmriprep.m
   Auto-discover and import subjects

Step 3: Smoothing
└─ batch_conn_03_smooth.m
   Apply spatial smoothing (FWHM configurable)

Step 4: Denoising
└─ batch_conn_04_denoise.m
   Confound regression + band-pass filtering
```

### Master Wrapper
- **run_conn_pipeline.sh** - Runs all 4 steps automatically

---

## 📚 Documentation

| File | Purpose | Read If... |
|------|---------|-----------|
| **GETTING_STARTED.md** | Checklist & walkthrough | You're new or setting up for first time |
| **PIPELINE_SUMMARY.md** | 5-minute overview | You want quick orientation |
| **MODULAR_PIPELINE_GUIDE.md** | Comprehensive reference | You need detailed information |
| **CONN_QUICK_REFERENCE.md** | Configurations & examples | You're running analyses |
| **INSTALL_CONN_STANDALONE.md** | Installation guide | CONN is not installed |
| **BATCH_FMRIPREP_GUIDE.md** | Old monolithic script | You're using legacy version |

---

## 🚀 Quick Commands

### Install CONN (one-time)
```bash
./install_conn_standalone.sh ~/conn_standalone
source ~/.bashrc
```

### Run Entire Pipeline (Easiest)
```bash
# Edit config in scripts first, then:
./run_conn_pipeline.sh /project/dir /fmriprep/dir
```

### Run Step-by-Step
```bash
source ~/.bashrc
conn batch batch_conn_01_project_setup.m
conn batch batch_conn_02_import_fmriprep.m
conn batch batch_conn_03_smooth.m
conn batch batch_conn_04_denoise.m
```

### View Results
```bash
ls /project/dir/conn_*/results/denoising/     # Final data
ls /project/dir/conn_*/results/qa/            # QA plots
```

---

## 📋 Configuration Quick Reference

### Step 1: Project Setup
```matlab
PROJECT_DIR = '/path/to/project'
NSUBJECTS = 50
REPETITION_TIME = 2.0
```

### Step 2: fMRIprep Import
```matlab
FMRIPREP_DIR = '/path/to/fmriprep'
BIDS_SPACE = 'MNI152NLin2009cAsym'  # Standard
```

### Step 3: Smoothing
```matlab
VOLUME_SMOOTHING_FWHM = 8  # 4, 6, 8, 10 common
```

### Step 4: Denoising
```matlab
BANDPASS_LOW = 0.008
BANDPASS_HIGH = Inf
DETRENDING_ORDER = 1
USE_STANDARD_CONFOUNDS = true
```

---

## 🎓 Recommended Reading Order

1. **[GETTING_STARTED.md](GETTING_STARTED.md)** - Checklist (5 min)
2. **[PIPELINE_SUMMARY.md](PIPELINE_SUMMARY.md)** - Overview (10 min)
3. **Individual script comments** - Before editing each file (5 min per file)
4. **[MODULAR_PIPELINE_GUIDE.md](MODULAR_PIPELINE_GUIDE.md)** - Details as needed

---

## 📁 File Structure

```
/data/local/software/conn-tools/
│
├── 📄 INDEX.md (this file)
├── 📄 README.md (original, now with CONN tools info)
│
├── 🚀 Installation
│   ├── install_conn_standalone.sh
│   └── INSTALL_CONN_STANDALONE.md
│
├── 🔧 Scripts (Main Pipeline)
│   ├── batch_conn_01_project_setup.m
│   ├── batch_conn_02_import_fmriprep.m
│   ├── batch_conn_03_smooth.m
│   └── batch_conn_04_denoise.m
│
├── 🎯 Wrapper & Config
│   ├── run_conn_pipeline.sh
│   ├── batch_fmriprep_config_template.json
│   ├── run_fmriprep_processing.sh (legacy)
│   └── batch_fmriprep_import_smooth_denoise.m (legacy)
│
├── 📚 Documentation (New)
│   ├── GETTING_STARTED.md (START HERE)
│   ├── PIPELINE_SUMMARY.md (Quick overview)
│   ├── MODULAR_PIPELINE_GUIDE.md (Comprehensive)
│   ├── CONN_QUICK_REFERENCE.md (Quick lookup)
│   └── INDEX.md (this file)
│
├── 📚 Documentation (Legacy)
│   └── BATCH_FMRIPREP_GUIDE.md
│
└── 🛠️ Original Tools
    ├── app.py
    ├── install_gui.py
    ├── scripts_py/
    ├── templates/
    ├── theme_template/
    ├── participants.*
    └── ... (other original files)
```

---

## ✨ Key Features

✅ **Modular** - 4 separate, independent scripts  
✅ **Flexible** - Run any subset of steps  
✅ **Documented** - Comprehensive guides + quick reference  
✅ **Automated** - Master wrapper runs all steps  
✅ **fMRIprep-Ready** - Auto-discovers and imports preprocessed data  
✅ **Configurable** - Easy-to-edit parameters in each script  
✅ **QA-Integrated** - Generates quality assurance plots  
✅ **Error-Recoverable** - Re-run specific steps without restarting

---

## 🎯 Typical Workflow

```
1. Install CONN (one-time)
   └─ ./install_conn_standalone.sh

2. Configure Pipeline (first time per study)
   ├─ Edit batch_conn_01_project_setup.m
   ├─ Edit batch_conn_02_import_fmriprep.m
   ├─ Edit batch_conn_03_smooth.m
   └─ Edit batch_conn_04_denoise.m

3. Run Pipeline (automatic)
   └─ ./run_conn_pipeline.sh /project /fmriprep

4. Review Quality
   └─ Check results/qa/ for QA plots

5. Run Connectivity Analyses
   └─ Define ROIs → Compute connectivity → Group stats
```

---

## 🆘 Need Help?

### Quick Questions
→ See **[CONN_QUICK_REFERENCE.md](CONN_QUICK_REFERENCE.md)**

### Getting Started
→ See **[GETTING_STARTED.md](GETTING_STARTED.md)**

### Detailed Info
→ See **[MODULAR_PIPELINE_GUIDE.md](MODULAR_PIPELINE_GUIDE.md)**

### Installation Issues
→ See **[INSTALL_CONN_STANDALONE.md](INSTALL_CONN_STANDALONE.md)**

### External Resources
- CONN Documentation: https://web.conn-toolbox.org/resources/conn-documentation
- CONN Forum: http://www.nitrc.org/forum/forum.php?forum_id=1144
- fMRIprep: https://fmriprep.org/

---

## 💾 Output Locations

After running pipeline:

```
PROJECT_DIR/
├── conn_project.mat                   # Main project file
├── conn_*/
│   └── results/
│       ├── preprocessing/             # Smoothed volumes (Step 3)
│       ├── denoising/                 # FINAL DENOISED DATA (Step 4) ← USE THIS
│       └── qa/                        # Quality assurance plots
└── conn_pipeline.log                  # Processing log
```

---

## ⚡ Performance Tips

| Task | Time | Tips |
|------|------|------|
| Step 1 (Setup) | ~1 min | Fast |
| Step 2 (Import) | 5-10 min | Depends on # subjects |
| Step 3 (Smooth) | 10-30 min | Can parallelize |
| Step 4 (Denoise) | 30-60 min | Longest step |
| **Total** | **1-2 hours** | For ~50 subjects |

**Speed up**: Use `--skip-smooth` if not needed

---

## 🔄 Version Info

- **Version**: 2.0 (Modular Pipeline)
- **Date**: February 2026
- **Status**: ✅ Production-ready
- **Location**: `/data/local/software/conn-tools/`

**Changes from v1.0**:
- ✅ Split monolithic script into 4 modules
- ✅ Added master wrapper for automation
- ✅ Improved documentation
- ✅ Better error handling
- ✅ Flexible re-running of steps

---

## 📞 Support & Contact

- **CONN**: info@conn-toolbox.org
- **Forum**: http://www.nitrc.org/forum/forum.php?forum_id=1144
- **fMRIprep**: https://fmriprep.org/

---

**Last Updated**: February 7, 2026  
**Location**: `/data/local/software/conn-tools/`  
**Status**: ✅ Ready to use
