#!/usr/bin/env python3
"""
CONN Modular Pipeline Wrapper
Orchestrates all 4 steps of the CONN processing pipeline in Python.

Usage:
    python3 run_conn_pipeline.py -p <project_dir> -f <fmriprep_dir> -b <bids_dir> [options]
    
Example:
    python3 run_conn_pipeline.py \
        -p /data/conn_project \
        -f /data/fmriprep \
        -b /data/bids_dataset
"""

import sys
import os
import argparse
import json
import re
import subprocess
import tempfile
import shutil
from pathlib import Path
from datetime import datetime
from collections import deque

# Colors for output
class Colors:
    HEADER = '\033[95m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def print_header():
    """Print pipeline header"""
    header = f"""
{Colors.GREEN}{Colors.BOLD}╔════════════════════════════════════════════════════════════════╗
║           CONN Modular Processing Pipeline                     ║
║  Project Setup → Import → Smooth → Denoise                     ║
╚════════════════════════════════════════════════════════════════╝{Colors.ENDC}
"""
    print(header)

def log(message, level="INFO", color=None):
    """Print timestamped log message"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    if color is None:
        if level == "ERROR":
            color = Colors.RED
        elif level == "WARNING":
            color = Colors.YELLOW
        elif level == "SUCCESS":
            color = Colors.GREEN
        else:
            color = Colors.CYAN
    
    print(f"{color}[{timestamp}] {level}: {message}{Colors.ENDC}")

def tail_file(path, line_count=200):
    """Return the last N lines of a text file."""
    try:
        with open(path, 'r', errors='ignore') as handle:
            return ''.join(deque(handle, maxlen=line_count))
    except Exception as exc:
        return f"[Unable to read {path}: {exc}]\n"

def append_conn_project_logs(project_dir, log_file):
    """Append CONN project log summaries to the pipeline log."""
    conn_project_dir = os.path.join(project_dir, 'conn_project')
    if not os.path.isdir(conn_project_dir):
        return

    entries = ['logfile.txt', 'statusfile.open']
    with open(log_file, 'a') as handle:
        handle.write('\n--- CONN project logs ---\n')
        for entry in entries:
            fullpath = os.path.join(conn_project_dir, entry)
            if os.path.isfile(fullpath):
                handle.write(f"\n[{entry}]\n")
                handle.write(tail_file(fullpath))

def extract_failure_subject_session(stdout_content):
    """Extract last 'Subject X Session Y' from CONN output if present."""
    matches = re.findall(r"Subject\s+(\d+)\s+Session\s+(\d+)", stdout_content)
    if not matches:
        return None, None
    subject_str, session_str = matches[-1]
    try:
        return int(subject_str), int(session_str)
    except ValueError:
        return None, None

def append_subject_diagnostics(log_file, fmriprep_dir, subject_index, session_index, sessions=None):
    """Append subject/session file diagnostics to the pipeline log."""
    if subject_index is None or session_index is None:
        return

    subject_dirs = sorted([p for p in Path(fmriprep_dir).glob('sub-*') if p.is_dir()])
    if subject_index < 1 or subject_index > len(subject_dirs):
        return

    subject_dir = subject_dirs[subject_index - 1]
    session_label = None
    if sessions and session_index <= len(sessions):
        session_label = sessions[session_index - 1]
    else:
        session_label = f"ses-{session_index}"

    func_dir = subject_dir / session_label / 'func'
    anat_dir = subject_dir / 'anat'
    func_files = []
    if func_dir.is_dir():
        func_files = sorted(func_dir.glob('*space-MNI152NLin2009cAsym*desc-preproc_bold.nii.gz'))

    anat_files = []
    if anat_dir.is_dir():
        anat_files = sorted(anat_dir.glob('*space-MNI152NLin2009cAsym*T1w.nii.gz'))
        if not anat_files:
            anat_files = sorted(anat_dir.glob('*_T1w.nii.gz'))

    with open(log_file, 'a') as handle:
        handle.write('\n--- Subject/session diagnostics ---\n')
        handle.write(f"Subject index: {subject_index}\n")
        handle.write(f"Session index: {session_index}\n")
        handle.write(f"Subject dir: {subject_dir}\n")
        handle.write(f"Session label: {session_label}\n")

        handle.write('\n[Functional files]\n')
        if not func_files:
            handle.write('  (none found)\n')
        for f in func_files:
            handle.write(f"  {f} ({f.stat().st_size} bytes)\n")

        handle.write('\n[Structural files]\n')
        if not anat_files:
            handle.write('  (none found)\n')
        for f in anat_files:
            handle.write(f"  {f} ({f.stat().st_size} bytes)\n")

        try:
            import nibabel as nib
            import numpy as np
            handle.write('\n[NIfTI read check]\n')
            for f in func_files + anat_files:
                try:
                    img = nib.load(str(f))
                    _ = np.asanyarray(img.dataobj[..., 0])
                    handle.write(f"  OK: {f} shape={img.shape}\n")
                except Exception as exc:
                    handle.write(f"  FAIL: {f} error={exc}\n")
        except Exception as exc:
            handle.write(f"\n[NIfTI read check unavailable: {exc}]\n")
    

def validate_fmriprep_derivatives(fmriprep_dir):
    """Run gunzip -t on key fMRIprep outputs to catch corrupt volumes early."""
    log("Validating fMRIprep derivative files...", "INFO")
    patterns = [
        "**/*desc-preproc_bold.nii.gz",
        "**/*space-MNI152NLin2009cAsym*T1w.nii.gz",
        "**/*_T1w.nii.gz",
    ]
    base_path = Path(fmriprep_dir)
    errors = []

    for pattern in patterns:
        for filepath in sorted(base_path.rglob(pattern)):
            if not filepath.is_file():
                continue
            try:
                result = subprocess.run(
                    ["gunzip", "-t", str(filepath)],
                    capture_output=True,
                    text=True,
                    timeout=20
                )
            except subprocess.TimeoutExpired:
                errors.append((filepath, "timeout"))
                continue

            if result.returncode != 0:
                detail = result.stderr.strip() or result.stdout.strip() or "unknown"
                errors.append((filepath, detail))

    if errors:
        log("Detected corrupt derivative files. Regenerate them before continuing.", "ERROR")
        for path, detail in errors:
            log(f"{path}: {detail}", "ERROR")
        return False

    log("Validated fMRIprep derivatives (BOLD + structural files)", "SUCCESS")
    return True

def extract_bids_metadata(bids_dir, script_dir):
    """Extract metadata from BIDS dataset"""
    log("Extracting metadata from BIDS dataset...")
    
    metadata_script = os.path.join(script_dir, 'scripts_py', 'read_bids_metadata.py')
    
    try:
        result = subprocess.run(
            ['python3', metadata_script, bids_dir, '--json'],
            capture_output=True,
            text=True,
            timeout=30
        )
        
        if result.returncode != 0:
            log(f"BIDS metadata extraction failed: {result.stderr}", "WARNING")
            return None
        
        metadata = json.loads(result.stdout)
        return metadata
        
    except subprocess.TimeoutExpired:
        log("BIDS metadata extraction timed out", "WARNING")
        return None
    except json.JSONDecodeError as e:
        log(f"Failed to parse BIDS metadata: {e}", "WARNING")
        return None
    except Exception as e:
        log(f"Error extracting BIDS metadata: {e}", "WARNING")
        return None

def validate_paths(args):
    """Validate input paths"""
    errors = []
    
    if not os.path.isdir(args.project_dir):
        os.makedirs(args.project_dir, exist_ok=True)
        log(f"Created project directory: {args.project_dir}")
    
    if not os.path.isdir(args.fmriprep_dir):
        errors.append(f"fMRIprep directory not found: {args.fmriprep_dir}")
    
    if not os.path.isdir(args.bids_dir):
        errors.append(f"BIDS directory not found: {args.bids_dir}")
    
    if errors:
        for error in errors:
            log(error, "ERROR")
        return False
    
    return True

def create_matlab_script(template_path, output_path, substitutions):
    """Create MATLAB script with variable substitutions"""
    try:
        with open(template_path, 'r') as f:
            content = f.read()
        
        # Perform substitutions
        for key, value in substitutions.items():
            content = content.replace(key, str(value))
        
        # Write output script
        with open(output_path, 'w') as f:
            f.write(content)
        
        return True
    except Exception as e:
        log(f"Failed to create MATLAB script: {e}", "ERROR")
        return False

def run_matlab_step(step_num, step_name, batch_script, conn_runner, project_dir, log_file, fmriprep_dir=None, sessions=None):
    """Run a MATLAB batch step with streamed output"""
    log(f"Step {step_num}: {step_name}", "INFO", Colors.BLUE)
    log("=" * 70, "INFO")
    
    try:
        if conn_runner.startswith('conn'):
            cmd = f"{conn_runner} batch {batch_script}"
        else:
            cmd = f"{conn_runner} \"run('{batch_script}'); quit;\""

        process = subprocess.Popen(
            cmd,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            bufsize=1,
            universal_newlines=True
        )

        stdout_lines = []
        while True:
            line = process.stdout.readline()
            if not line and process.poll() is not None:
                break
            if line:
                print(line, end='')
                stdout_lines.append(line)

        stdout_content = ''.join(stdout_lines)
        return_code = process.wait()

        if return_code != 0 or "Error" in stdout_content or "ERROR" in stdout_content:
            log(f"Step {step_num} FAILED", "ERROR")
            with open(log_file, 'a') as f:
                f.write(f"\n[FAILED] Step {step_num}: {step_name}\n")
                f.write(f"Command: {cmd}\n")
                f.write(stdout_content)
            append_conn_project_logs(project_dir, log_file)
            if fmriprep_dir:
                subject_index, session_index = extract_failure_subject_session(stdout_content)
                append_subject_diagnostics(log_file, fmriprep_dir, subject_index, session_index, sessions)
            return False

        log(f"Step {step_num} COMPLETED", "SUCCESS")
        return True

    except Exception as e:
        log(f"Step {step_num} failed: {e}", "ERROR")
        return False

def main():
    """Main pipeline orchestration"""
    print_header()
    
    # Parse arguments
    parser = argparse.ArgumentParser(
        description='CONN Modular Processing Pipeline',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python3 run_conn_pipeline.py -p /data/conn -f /data/fmriprep -b /data/bids
  python3 run_conn_pipeline.py -p /data/conn -f /data/fmriprep -b /data/bids --fwhm 6
  python3 run_conn_pipeline.py -p /data/conn -f /data/fmriprep -b /data/bids --skip-smooth
        """
    )
    
    # Required arguments
    parser.add_argument('-p', '--project-dir', required=True,
                        help='Directory where CONN project will be created/saved')
    parser.add_argument('-f', '--fmriprep-dir', required=True,
                        help='Root directory of fMRIprep preprocessed data')
    parser.add_argument('-b', '--bids-dir', required=True,
                        help='Root directory of BIDS dataset')
    
    # Optional arguments
    parser.add_argument('-i', '--install-dir', default=os.path.expanduser('~/conn_standalone'),
                        help='CONN installation directory (default: ~/conn_standalone)')
    parser.add_argument('--fwhm', type=int, default=8,
                        help='Smoothing kernel size in mm (default: 8)')
    parser.add_argument('--config', type=str,
                        help='Path to pipeline configuration JSON file')
    parser.add_argument('--no-qa', action='store_true',
                        help='Do not generate QA plots')
    
    # Skip options
    parser.add_argument('--skip-setup', action='store_true',
                        help='Skip Step 1 (project already exists)')
    parser.add_argument('--skip-import', action='store_true',
                        help='Skip Step 2 (data already imported)')
    parser.add_argument('--skip-smooth', action='store_true',
                        help='Skip Step 3 (no smoothing)')
    parser.add_argument('--skip-denoise', action='store_true',
                        help='Skip Step 4 (no denoising)')
    
    args = parser.parse_args()
    
    # Load config file if provided
    if args.config and os.path.exists(args.config):
        with open(args.config, 'r') as f:
            config = json.load(f)
        # Override args with config values
        if 'smoothing' in config and config['smoothing'].get('enabled', True):
            args.fwhm = config['smoothing'].get('fwhm', args.fwhm)
    
    # Convert paths to absolute paths and remove trailing slashes
    args.project_dir = os.path.abspath(args.project_dir).rstrip('/')
    args.fmriprep_dir = os.path.abspath(args.fmriprep_dir).rstrip('/')
    args.bids_dir = os.path.abspath(args.bids_dir).rstrip('/')
    args.install_dir = os.path.abspath(args.install_dir).rstrip('/')
    
    # Get script directory
    script_dir = os.path.dirname(os.path.abspath(__file__))
    batch_script_dir = os.path.join(script_dir, 'scripts', 'conn')
    
    # Setup logging
    log_file = os.path.join(args.project_dir, 'conn_pipeline.log')
    
    # Print configuration
    print(f"\n{Colors.BLUE}Configuration:{Colors.ENDC}")
    print(f"  Project directory:  {args.project_dir}")
    print(f"  fMRIprep directory: {args.fmriprep_dir}")
    print(f"  BIDS directory:     {args.bids_dir}")
    print(f"  CONN install dir:   {args.install_dir}")
    print(f"  Smoothing FWHM:     {args.fwhm} mm")
    print(f"  Generate QA:        {not args.no_qa}")
    print(f"  Log file:           {log_file}\n")
    
    # Validate paths
    if not validate_paths(args):
        sys.exit(1)
    
    # Extract BIDS metadata
    bids_metadata = extract_bids_metadata(args.bids_dir, script_dir)
    
    if bids_metadata:
        num_subjects = bids_metadata.get('num_subjects', 30)
        tr = bids_metadata.get('tr', 2.0)
        sessions = bids_metadata.get('sessions', [])
        
        log(f"✓ BIDS metadata extracted", "SUCCESS")
        print(f"    Subjects:  {num_subjects}")
        print(f"    TR:        {tr:.3f} seconds")
        if sessions:
            print(f"    Sessions:  {', '.join(sessions)}")
    else:
        log("Using default parameters (could not extract BIDS metadata)", "WARNING")
        num_subjects = 30
        tr = 2.0
        sessions = []
    
    print()
    
    # Check CONN availability
    conn_runner = None
    if shutil.which('conn'):
        conn_runner = 'conn'
        log(f"Using CONN standalone: {shutil.which('conn')}", "SUCCESS")
    elif shutil.which('matlab'):
        conn_runner = 'matlab -r'
        log(f"Using MATLAB: {shutil.which('matlab')}", "SUCCESS")
    else:
        log("CONN or MATLAB not found in PATH", "ERROR")
        sys.exit(1)
    
    print()
    
    # Step 1: Project Setup
    if not args.skip_setup:
        log(f"Step 1: Project Setup", "INFO", Colors.BLUE)
        log("=" * 70, "INFO")
        
        setup_script_template = os.path.join(batch_script_dir, 'batch_conn_01_project_setup.m')
        setup_script = os.path.join(args.project_dir, 'batch_conn_01_setup.m')
        
        substitutions = {
            "PROJECT_DIR         = '/path/to/project/directory'": f"PROJECT_DIR         = '{args.project_dir}'",
            "BIDS_DIR            = '/path/to/bids/dataset'": f"BIDS_DIR            = '{args.bids_dir}'",
            'NSUBJECTS           = 30': f'NSUBJECTS           = {num_subjects}',
            'REPETITION_TIME     = 2.0': f'REPETITION_TIME     = {tr}',
        }
        
        if create_matlab_script(setup_script_template, setup_script, substitutions):
            if not run_matlab_step(1, 'Project Setup', setup_script, conn_runner, args.project_dir, log_file):
                sys.exit(1)
        else:
            sys.exit(1)
        
        print()
    
    # Step 2: Import fMRIprep Data
    if not args.skip_import:
        log(f"Step 2: Import fMRIprep Data", "INFO", Colors.BLUE)
        log("=" * 70, "INFO")

        if not validate_fmriprep_derivatives(args.fmriprep_dir):
            sys.exit(1)
        
        import_script_template = os.path.join(batch_script_dir, 'batch_conn_02_import_fmriprep.m')
        import_script = os.path.join(args.project_dir, 'batch_conn_02_import.m')
        
        substitutions = {
            "PROJECT_DIR     = '/path/to/project/directory'": f"PROJECT_DIR     = '{args.project_dir}'",
            "BIDS_DIR        = '/path/to/bids/dataset'": f"BIDS_DIR        = '{args.bids_dir}'",
            "FMRIPREP_DIR    = '/path/to/fmriprep/dataset'": f"FMRIPREP_DIR    = '{args.fmriprep_dir}'",
        }
        
        if create_matlab_script(import_script_template, import_script, substitutions):
            if not run_matlab_step(2, 'Import fMRIprep Data', import_script, conn_runner, args.project_dir, log_file, fmriprep_dir=args.fmriprep_dir, sessions=sessions):
                sys.exit(1)
        else:
            sys.exit(1)
        
        print()
    
    # Step 3: Smoothing
    if not args.skip_smooth:
        log(f"Step 3: Spatial Smoothing", "INFO", Colors.BLUE)
        log("=" * 70, "INFO")
        
        smooth_script_template = os.path.join(batch_script_dir, 'batch_conn_03_smooth.m')
        smooth_script = os.path.join(args.project_dir, 'batch_conn_03_smooth.m')
        
        substitutions = {
            "PROJECT_DIR     = '/path/to/project/directory'": f"PROJECT_DIR     = '{args.project_dir}'",
            'VOLUME_SMOOTHING_FWHM    = 8': f'VOLUME_SMOOTHING_FWHM    = {args.fwhm}',
        }
        
        if create_matlab_script(smooth_script_template, smooth_script, substitutions):
            if not run_matlab_step(3, 'Spatial Smoothing', smooth_script, conn_runner, args.project_dir, log_file):
                sys.exit(1)
        else:
            sys.exit(1)
        
        print()
    
    # Step 4: Denoising
    if not args.skip_denoise:
        log(f"Step 4: Denoising", "INFO", Colors.BLUE)
        log("=" * 70, "INFO")
        
        denoise_script_template = os.path.join(batch_script_dir, 'batch_conn_04_denoise.m')
        denoise_script = os.path.join(args.project_dir, 'batch_conn_04_denoise.m')
        
        generate_qa = 'true' if not args.no_qa else 'false'
        substitutions = {
            "PROJECT_DIR     = '/path/to/project/directory'": f"PROJECT_DIR     = '{args.project_dir}'",
            'GENERATE_QA_PLOTS = true': f'GENERATE_QA_PLOTS = {generate_qa}',
        }
        
        if create_matlab_script(denoise_script_template, denoise_script, substitutions):
            if not run_matlab_step(4, 'Denoising', denoise_script, conn_runner, args.project_dir, log_file):
                sys.exit(1)
        else:
            sys.exit(1)
        
        print()
    
    # Success
    print()
    log("╔════════════════════════════════════════════════════════════════╗", "SUCCESS")
    log("║                  PIPELINE COMPLETED SUCCESSFULLY                ║", "SUCCESS")
    log("╚════════════════════════════════════════════════════════════════╝", "SUCCESS")
    print(f"\nProject directory: {args.project_dir}")
    print(f"Log file: {log_file}")
    print()

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{Colors.YELLOW}Pipeline interrupted by user{Colors.ENDC}")
        sys.exit(130)
    except Exception as e:
        print(f"\n{Colors.RED}Unexpected error: {e}{Colors.ENDC}")
        sys.exit(1)
