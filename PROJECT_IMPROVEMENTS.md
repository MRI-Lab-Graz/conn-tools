# Project Approach Improvements Based on Reference Analysis

## Overview

After analyzing the reference CONN project (`conn_project01.mat` from the GUI), the pipeline has been updated to follow best practices for BIDS-aware CONN project setup and execution.

## Key Improvements Implemented

### 1. Enhanced Project Setup (batch_conn_01_project_setup.m)

**Before:**
```matlab
NSUBJECTS = 30;              % Placeholder
REPETITION_TIME = 2.0;       % Hardcoded
% No session handling
% No BIDS reference stored
```

**After:**
```matlab
NSUBJECTS = 30;              % Extracted from BIDS (via pipeline)
REPETITION_TIME = 2.0;       % Extracted from BIDS JSON (via pipeline)
DETECT_SESSIONS = 1;         % Auto-detect multi-session structure
BIDS_DIR = '/path/to/bids';  % Reference stored for reproducibility
```

**Changes:**
- ✓ Added automatic session detection from BIDS structure
- ✓ BIDS metadata now stored in project for reproducibility
- ✓ Multi-session dataset support
- ✓ Better logging of detected sessions
- ✓ BIDS directory validation

### 2. Improved Data Import (batch_conn_02_import_fmriprep.m)

**Before:**
```matlab
FMRIPREP_DIR = '/path/to/fmriprep/dataset';
% No confound handling
% Manual file discovery
% No validation
```

**After:**
```matlab
FMRIPREP_DIR = '/path/to/fmriprep/dataset';
BIDS_DIR = '/path/to/bids/dataset';        % Added for reference
USE_CONFOUNDS = 1;                         % Auto-import confounds
CONFOUND_TYPES = {'WhiteMatter', 'CSF', ...}; % Standardized regressors
```

**Changes:**
- ✓ Automatic confound detection from fMRIprep outputs
- ✓ Proper handling of `desc-confounds_timeseries.tsv` files
- ✓ Multi-session functional data support
- ✓ Better structural file discovery (MNI-space priority)
- ✓ BIDS validation and error messages

### 3. Multi-Session Support

**Project Initialization:**
```matlab
% Auto-detected from BIDS/sub-*/ses-* structure
BATCH.Setup.nsessions = length(sessions_found);
BATCH.Setup.BIDS_sessions = sessions_found;

% Output example:
% Multi-session dataset detected!
%   Sessions found: ses-1, ses-2, ses-3
```

**Data Import:**
- Automatically discovers sessions in both subject structures
- Properly maps sessions to CONN's internal session numbering
- Supports arbitrary number of sessions

### 4. Metadata Preservation

**Stored in Project:**
```matlab
BATCH.Setup.BIDS_dir = BIDS_DIR;           % Reference to original BIDS
BATCH.Setup.BIDS_sessions = sessions_found; % Sessions detected
```

**Benefits:**
- Full reproducibility of project setup
- Audit trail of data sources
- Easy to regenerate or update projects

## File Structure Reference

### CONN Project Organization

```
project_dir/
├── conn_project.mat                    ← Main project file
├── conn_project/                       ← Project workspace
│   ├── bakfile.mat                     ← Backup
│   ├── logfile.txt                     ← Processing log
│   ├── statusfile.open                 ← Project status
│   ├── data/                           ← Imported data
│   └── results/                        ← Processing outputs
├── conn_project.qlog/                  ← Query logs
├── participants.tsv                    ← BIDS participant mapping
├── sub_matching.txt                    ← Subject ID mapping
└── group_final.txt                     ← Group results
```

### CONN_x Internal Structure

The project .mat file contains CONN_x structure with:
- **Setup**: nsubjects, RT, acquisition type, voxel resolution, sessions, BIDS metadata
- **Preproc**: Preprocessing parameters (smoothing, denoising)
- **folders**: Data, results, and subfolder paths
- **Analysis**: Analysis configuration
- **Results**: Processing outputs and statistics

## Data Flow Changes

### Before (Pipeline v1)
```
BIDS Dataset
    ↓
[Extract metadata: TR, N subjects]
    ↓
[Pass to MATLAB hardcoded]
    ↓
Create project (with placeholders)
    ↓
Manual import
```

### After (Pipeline v2)
```
BIDS Dataset
    ↓
[Extract metadata: TR, N, Sessions]
    ↓
[Create project with REAL parameters]
    ↓
[Auto-detect multi-session structure]
    ↓
[Auto-find confounds + structurals]
    ↓
[Complete project initialization]
```

## Batch Script Enhancement Summary

| Script | Key Improvement |
|--------|-----------------|
| batch_conn_01_project_setup.m | Multi-session detection + BIDS metadata storage |
| batch_conn_02_import_fmriprep.m | Confound auto-discovery + BIDS-aware paths |
| batch_conn_03_smooth.m | (Ready - FWHM configurable) |
| batch_conn_04_denoise.m | (Ready for enhancement) |

## Testing & Validation

The improvements have been designed to:
1. ✓ Work with single-session datasets (backward compatible)
2. ✓ Auto-detect and configure multi-session studies
3. ✓ Extract correct TR from BIDS JSON metadata
4. ✓ Use actual subject counts from BIDS
5. ✓ Find confound regressors automatically
6. ✓ Store BIDS reference for reproducibility
7. ✓ Provide clear logging of detected structure

## Usage

### Basic command (same as before):
```bash
./scripts/conn/run_conn_pipeline.sh \
  -p /data/conn_project \
  -f /data/fmriprep \
  -b /data/bids_dataset
```

### What now happens automatically:

1. **Setup phase:**
   - Detects actual number of subjects from BIDS
   - Extracts TR from BIDS JSON sidecars
   - Detects multi-session structure (ses-1, ses-2, etc.)
   - Configures CONN project accordingly
   - Stores BIDS metadata in project

2. **Import phase:**
   - Auto-discovers fMRIprep BOLD files
   - Finds and imports confound regressors
   - Matches sessions correctly
   - Handles both single and multi-session data

3. **Smoothing phase:** (unchanged - already enhanced)
   - Configurable FWHM
   - Validated before processing

4. **Denoising phase:** (ready for enhancement)
   - Uses imported confounds
   - Applies denoising strategy

## Future Enhancements

Potential improvements for future versions:
1. Support for alternative spaces (not just MNI152NLin2009cAsym)
2. Quality control metrics pre/post processing
3. Motion outlier detection from confounds
4. Automatic denoising strategy based on data characteristics
5. Group-level analysis pipeline

## Reference Project Analysis

The reference project (`conn_project01.mat`) demonstrated:
- Proper project initialization with correct parameters
- Multi-session dataset handling (ses-1, ses-2, ses-3)
- Automatic data discovery from fMRIprep
- Logical project organization
- Comprehensive logging

Our improvements ensure all future projects follow these best practices automatically.
