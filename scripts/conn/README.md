# CONN Tools Organization

All CONN-related scripts, documentation, and tools have been organized under the `scripts/conn/` directory.

## 📁 Directory Structure

```
conn-tools/
├── scripts/
│   └── conn/
│       ├── 📄 MATLAB SCRIPTS (4-Step Modular Pipeline)
│       │   ├── batch_conn_01_project_setup.m
│       │   ├── batch_conn_02_import_fmriprep.m
│       │   ├── batch_conn_03_smooth.m
│       │   └── batch_conn_04_denoise.m
│       │
│       ├── 🔧 AUTOMATION & INSTALLATION
│       │   ├── run_conn_pipeline.sh (Master wrapper)
│       │   ├── install_conn_standalone.sh
│       │   └── run_fmriprep_processing.sh (legacy)
│       │
│       ├── 📚 DOCUMENTATION
│       │   ├── INDEX.md (START HERE - Complete navigation)
│       │   ├── GETTING_STARTED.md (Checklist for first-time users)
│       │   ├── PIPELINE_SUMMARY.md (5-minute overview)
│       │   ├── MODULAR_PIPELINE_GUIDE.md (Comprehensive reference)
│       │   ├── CONN_QUICK_REFERENCE.md (Quick lookup)
│       │   ├── INSTALL_CONN_STANDALONE.md (Installation guide)
│       │   └── BATCH_FMRIPREP_GUIDE.md (Legacy script docs)
│       │
│       ├── 🔨 CONFIGURATION
│       │   ├── batch_fmriprep_import_smooth_denoise.m (legacy)
│       │   └── batch_fmriprep_config_template.json
│       │
│       └── README.md (This file)
│
├── scripts_py/ (Original Python scripts)
├── templates/ (Original Flask templates)
├── static/ (Original static files)
├── theme_template/ (Original theme)
├── app.py (Original Flask app)
├── install_gui.py (Original GUI installer)
├── participants.* (Original participant files)
├── check_sessions.sh (Original shell script)
├── export_conn_light.sh (Original export script)
├── map_conn_ids.py (Original ID mapping)
├── requirements.txt (Original requirements)
└── README.md (Original project README)
```

## 🚀 Quick Start

All CONN tools are now under `scripts/conn/`. 

### Running the Pipeline

```bash
cd /data/local/software/conn-tools/scripts/conn

# Load CONN environment
source ~/.bashrc

# Run the full pipeline (flag-based syntax - recommended)
./run_conn_pipeline.sh -p /project/dir -f /fmriprep/dir

# Or specify custom installation directory
./run_conn_pipeline.sh -p /project/dir -f /fmriprep/dir -i /opt/conn

# Legacy positional syntax still supported
./run_conn_pipeline.sh /project/dir /fmriprep/dir
```

### Accessing Documentation

```bash
cd scripts/conn

# Start here
cat INDEX.md

# Getting started checklist
cat GETTING_STARTED.md

# Quick reference
cat CONN_QUICK_REFERENCE.md

# Comprehensive guide
cat MODULAR_PIPELINE_GUIDE.md
```

## 📚 Documentation Map

**First Time?**
1. `scripts/conn/INDEX.md` - Navigation hub
2. `scripts/conn/GETTING_STARTED.md` - Checklist
3. `scripts/conn/PIPELINE_SUMMARY.md` - Overview

**Quick Reference?**
- `scripts/conn/CONN_QUICK_REFERENCE.md` - Configurations & examples

**Need Details?**
- `scripts/conn/MODULAR_PIPELINE_GUIDE.md` - Comprehensive reference

**Installation?**
- `scripts/conn/INSTALL_CONN_STANDALONE.md` - Installation guide

## 🎯 Files Organized

### MATLAB Batch Scripts (4 Modular Steps)
- `batch_conn_01_project_setup.m` - Create CONN project
- `batch_conn_02_import_fmriprep.m` - Import fMRIprep data
- `batch_conn_03_smooth.m` - Apply smoothing
- `batch_conn_04_denoise.m` - Denoising

### Automation & Installation
- `run_conn_pipeline.sh` - Master wrapper (runs all 4 steps)
- `install_conn_standalone.sh` - Install CONN standalone
- `run_fmriprep_processing.sh` - Legacy wrapper

### Configuration Templates
- `batch_fmriprep_config_template.json` - JSON config template
- `batch_fmriprep_import_smooth_denoise.m` - Legacy all-in-one script

### Documentation (7 Files)
- `INDEX.md` - Complete navigation hub
- `GETTING_STARTED.md` - Step-by-step checklist
- `PIPELINE_SUMMARY.md` - Overview & workflow
- `MODULAR_PIPELINE_GUIDE.md` - Comprehensive guide (9.2K)
- `CONN_QUICK_REFERENCE.md` - Quick reference
- `INSTALL_CONN_STANDALONE.md` - Installation instructions
- `BATCH_FMRIPREP_GUIDE.md` - Legacy script documentation

## ✅ Benefits of Organization

- ✅ All CONN tools in one place
- ✅ Easy to find documentation
- ✅ Separated from original project files
- ✅ Easy to version control
- ✅ Clean project structure

## 🔗 Related

Original project files remain in the root directory:
- `app.py` - Main Flask application
- `scripts_py/` - Python utility scripts
- `templates/` - HTML templates
- `participants.*` - Participant data
- etc.

---

**Location**: `/data/local/software/conn-tools/scripts/conn/`  
**Version**: 2.0 (Modular)  
**Status**: ✅ Ready to use
