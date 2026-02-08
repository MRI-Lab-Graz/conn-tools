# BIDS Integration for CONN Pipeline

## Overview

The CONN pipeline now automatically extracts acquisition parameters from BIDS datasets, eliminating the need for manual configuration of project settings like TR (Repetition Time) and number of subjects.

## Changes Made

### 1. New BIDS Metadata Reader (`scripts_py/read_bids_metadata.py`)

A Python utility that reads BIDS dataset structure and extracts:
- **Number of subjects**: Counts `sub-*` directories
- **TR (RepetitionTime)**: Extracted from `*_bold.json` sidecars
- **Sessions**: Detects multi-session datasets
- **Dataset name and type**: From `dataset_description.json`
- **Number of functional files**: Counts `*_bold.nii*` files

**Usage:**
```bash
python3 scripts_py/read_bids_metadata.py /path/to/bids
python3 scripts_py/read_bids_metadata.py /path/to/bids --json
```

### 2. Updated Pipeline Wrapper (`scripts/conn/run_conn_pipeline.sh`)

- **New required argument**: `-b, --bids-dir <path>` to specify the BIDS dataset root
- **Automatic metadata extraction**: Calls `read_bids_metadata.py` to extract TR and subject count
- **Parameter substitution**: Passes extracted values to MATLAB scripts via `sed` replacements

**Updated usage:**
```bash
./run_conn_pipeline.sh -p <project_dir> -f <fmriprep_dir> -b <bids_dir> [options]
```

**Example:**
```bash
./run_conn_pipeline.sh \
  -p /data/conn_project \
  -f /data/fmriprep \
  -b /data/bids_dataset
```

### 3. Updated MATLAB Setup Script (`scripts/conn/batch_conn_01_project_setup.m`)

- **BIDS directory variable**: Added `BIDS_DIR` parameter
- **Automatic parameter substitution**: The bash wrapper now automatically updates:
  - `NSUBJECTS`: Set from BIDS metadata
  - `REPETITION_TIME`: Set from BIDS JSON sidecars
  - `BIDS_DIR`: Set to the provided BIDS directory
- **Improved output**: Now clearly indicates that values were extracted from BIDS

## How It Works

### Data Flow

1. **User provides BIDS directory** to `run_conn_pipeline.sh`
2. **Python extracts metadata**: `read_bids_metadata.py` analyzes BIDS structure
3. **Parameters are parsed**: Bash extracts TR and subject count from JSON output
4. **MATLAB script is customized**: `sed` substitutions inject extracted values
5. **CONN project is created**: With correct parameters from the start

### Example Flow

```
Input: /data/bids_dataset

↓ [read_bids_metadata.py analyzes BIDS]

Output: {
  "num_subjects": 152,
  "tr": 1.4,
  "sessions": ["ses-1", "ses-2", "ses-3"],
  ...
}

↓ [Bash parses JSON]

Variables set:
  BIDS_NUM_SUBJECTS=152
  BIDS_TR=1.4

↓ [sed substitutes into MATLAB]

MATLAB receives:
  NSUBJECTS = 152
  REPETITION_TIME = 1.4
  BIDS_DIR = /data/bids_dataset
```

## Benefits

1. **No manual configuration**: Parameters are automatically extracted from BIDS
2. **Accuracy**: Guarantees consistency between BIDS metadata and CONN project
3. **Multi-session support**: Detects and handles multi-session datasets
4. **Error handling**: Gracefully falls back to defaults if metadata extraction fails
5. **Transparency**: Clearly shows extracted values in pipeline output

## Example Output

```
═══════════════════════════════════════════════════════════════
Step 1: Project Setup
════════════════════════════════════════════════════════════════
Initializing MATLAB Runtime version 9.12
Loading MCR. Please wait...

============================================
CONN Project Setup (Step 1/4)
============================================

Project settings:
  Name: My_fMRI_Project
  Directory: /data/local/069_BW01/conn
  BIDS: /data/bids_dataset
  Subjects: 152 (extracted from BIDS dataset)
  TR: 1.400 seconds (extracted from BIDS JSON metadata)

Creating CONN project skeleton...
✓ Project Setup Complete
```

## Backward Compatibility

The pipeline **requires** the BIDS directory argument (`-b`). This is a breaking change from the previous version, but it ensures:
- Correct project initialization from the start
- No manual parameter tweaking needed
- Automatic handling of different datasets

## Troubleshooting

### "Could not extract BIDS metadata"

**Cause**: Python script failed to read BIDS structure

**Solutions**:
1. Verify BIDS directory path is correct
2. Ensure dataset has `sub-*` directories with functional data
3. Check that `*_bold.json` sidecars exist in the functional directories

Example BIDS structure:
```
bids_dataset/
├── dataset_description.json
├── sub-001/
│   ├── ses-1/
│   │   └── func/
│   │       ├── sub-001_ses-1_task-rest_bold.nii.gz
│   │       └── sub-001_ses-1_task-rest_bold.json  ← Contains TR
│   └── ses-2/
│       └── func/
└── sub-002/
    └── func/
        ├── sub-002_task-rest_bold.nii.gz
        └── sub-002_task-rest_bold.json  ← Contains TR
```

### Missing TR value

If the script finds no TR in JSON files, it defaults to 2.0 seconds. To use a specific TR:
1. Ensure your fMRI files have corresponding `.json` sidecar files
2. The JSON must contain `"RepetitionTime"` field

## Testing

Test the metadata reader with your BIDS dataset:

```bash
cd /data/local/software/conn-tools
python3 scripts_py/read_bids_metadata.py /your/bids/path
python3 scripts_py/read_bids_metadata.py /your/bids/path --json
```

## References

- [BIDS Specification](https://bids-standard.github.io/)
- [BIDS JSON Task Sidecars](https://bids-standard.github.io/bids-validator/)
- CONN Documentation: http://www.nitrc.org/projects/conn
