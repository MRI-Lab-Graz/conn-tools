# Python CONN Pipeline Wrapper

## Overview

The Python pipeline wrapper (`run_conn_pipeline.py`) is a complete rewrite of the original bash script, providing:

- **Automatic BIDS metadata extraction** (subjects, TR, sessions)
- **Reliable subprocess handling** without fragile pipes or command substitutions  
- **Comprehensive error handling** with clear, actionable error messages
- **Native JSON parsing** instead of sed/jq workarounds
- **Color-coded logging** with timestamps to stdout and log files
- **Skip options** to resume from any step
- **Better platform compatibility** across Linux/macOS/Windows

## Installation

No additional dependencies needed beyond what's already required:
- Python 3.6+
- scipy (for BIDS metadata reading)
- CONN standalone OR MATLAB + CONN toolbox
- The existing MATLAB batch templates in `scripts/conn/`

## Usage

### Basic Usage

```bash
python3 run_conn_pipeline.py \
    -p /path/to/conn_project \
    -f /path/to/fmriprep \
    -b /path/to/bids_dataset
```

### Full Example

```bash
python3 run_conn_pipeline.py \
    -p /data/conn_project \
    -f /data/fmriprep \
    -b /data/bids_dataset \
    --fwhm 6 \
    --no-qa
```

### With Skip Options (Resume Processing)

```bash
# Skip project setup (project already exists)
python3 run_conn_pipeline.py -p /data/conn -f /data/fmriprep -b /data/bids --skip-setup

# Skip to denoise only
python3 run_conn_pipeline.py -p /data/conn -f /data/fmriprep -b /data/bids --skip-setup --skip-import --skip-smooth
```

## Arguments

| Argument | Short | Required | Description |
|----------|-------|----------|-------------|
| `--project-dir` | `-p` | Yes | Directory where CONN project will be created/saved |
| `--fmriprep-dir` | `-f` | Yes | Root directory of fMRIprep preprocessed data |
| `--bids-dir` | `-b` | Yes | Root directory of BIDS dataset |
| `--install-dir` | `-i` | No | CONN installation directory (default: `~/conn_standalone`) |
| `--fwhm` | - | No | Smoothing kernel size in mm (default: 8) |
| `--no-qa` | - | No | Don't generate QA plots |
| `--skip-setup` | - | No | Skip Step 1 (project already exists) |
| `--skip-import` | - | No | Skip Step 2 (data already imported) |
| `--skip-smooth` | - | No | Skip Step 3 (no smoothing) |
| `--skip-denoise` | - | No | Skip Step 4 (no denoising) |

## Output

The pipeline creates:

```
project_dir/
├── conn_project.mat              # CONN project file
├── conn_project/                 # Project directory with data/results
├── batch_conn_01_setup.m         # Generated Step 1 script (with paths)
├── batch_conn_02_import.m        # Generated Step 2 script (with paths)
├── batch_conn_03_smooth.m        # Generated Step 3 script (with paths)
├── batch_conn_04_denoise.m       # Generated Step 4 script (with paths)
└── conn_pipeline.log             # Detailed execution log
```

## Features

### BIDS Integration

Automatically extracts from BIDS dataset:
- **Subjects**: Number of subjects (not hardcoded)
- **TR**: Repetition time from JSON sidecars
- **Sessions**: Detected from BIDS folder structure (ses-1, ses-2, etc.)
- **Subject list**: For reference and validation

### Multi-Session Support

Automatically detects and configures:
```
ses-1/
ses-2/  ← detected from BIDS structure
ses-3/
```

All sessions are properly configured in CONN project setup.

### Comprehensive Logging

Each step is logged with:
- Timestamp
- Status (INFO, SUCCESS, WARNING, ERROR)
- Color-coded output for terminal readability
- Complete session saved to `conn_pipeline.log`

Example:
```
[2026-02-08 09:22:02] SUCCESS: ✓ BIDS metadata extracted
    Subjects:  23
    TR:        1.400 seconds
    Sessions:  ses-1, ses-2, ses-3
```

### Error Handling

Failures are reported clearly:
```
[2026-02-08 09:26:23] ERROR: Step 2 FAILED
[2026-02-08 09:26:23] ERROR: Error output: ERROR: Subject 1 does not have...
```

Errors are:
- Printed to terminal
- Saved to log file
- Include the full MATLAB/CONN error output
- Include the exact command that failed

## Migration from Bash Script

If you were previously using `scripts/conn/run_conn_pipeline.sh`, this Python version is a direct replacement:

**Old (Bash):**
```bash
bash scripts/conn/run_conn_pipeline.sh -p /data/conn -f /data/fmriprep -b /data/bids
```

**New (Python):**
```bash
python3 run_conn_pipeline.py -p /data/conn -f /data/fmriprep -b /data/bids
```

All arguments are the same. The Python version is more robust and maintainable.

## Troubleshooting

### "CONN or MATLAB not found in PATH"

Install CONN standalone or MATLAB, and ensure it's in your PATH:

```bash
# Check if conn is available
which conn

# Or check MATLAB
which matlab
```

### "Project file not found"

Run with `--skip-setup` set to `False` (run Step 1) or ensure the project directory path matches.

### "Subject does not have condition data"

This is a CONN configuration issue. The batch scripts need to set `Allow missing data` for multi-session datasets. Add to batch script:

```matlab
BATCH.Setup.conditions.allconditions = 0;  % Allow missing conditions
```

### "BIDS metadata not extracted"

Check BIDS directory structure:
```
rawdata/
├── sub-01/
│   ├── ses-1/
│   │   └── func/
│   │       └── sub-01_ses-1_task-rest_bold.json
│   └── ses-2/...
└── sub-02/...
```

## Key Improvements Over Bash Script

| Issue | Bash | Python |
|-------|------|--------|
| JSON parsing | sed/jq hacks | Native json module |
| Command substitution failures | Silent, exit code 2 | Clear error messages |
| Path handling | Fragile with quotes/spaces | Robust path handling |
| Error suppression | 2>/dev/null loses context | Full error capture |
| Process management | Complex shell logic | subprocess module |
| Cross-platform | Bash-specific issues | Works on Linux/macOS/Windows |
| Debugging | Hard to trace errors | Timestamped logging |
| Code maintenance | String substitutions | Readable Python code |

## Performance

Typical processing times per step (23 subjects, 3 sessions):
- Step 1 (Setup): 30 seconds
- Step 2 (Import): 5-10 minutes (depends on number of subjects/sessions)
- Step 3 (Smoothing): 10-30 minutes
- Step 4 (Denoising): 30-60 minutes

Total: ~2-3 hours for full pipeline

## License

Same as the CONN-tools project.
