#!/bin/bash
################################################################################
# CONN fMRIprep Processing Wrapper Script
#
# This script simplifies running the MATLAB batch processing for:
# - Importing fMRIprep data
# - Spatial smoothing
# - Denoising
#
# Usage:
#   ./run_fmriprep_processing.sh <project_dir> <fmriprep_dir>
#
# Example:
#   ./run_fmriprep_processing.sh /data/conn_projects /data/fmriprep
#
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MATLAB_SCRIPT="${SCRIPT_DIR}/batch_fmriprep_import_smooth_denoise.m"
CONFIG_TEMPLATE="${SCRIPT_DIR}/batch_fmriprep_config_template.json"

# Parse command line arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo ""
    echo "Usage: $0 <project_dir> <fmriprep_dir>"
    echo ""
    echo "Arguments:"
    echo "  <project_dir>    Directory where CONN project will be saved"
    echo "  <fmriprep_dir>   Root directory of fMRIprep preprocessed data"
    echo ""
    echo "Example:"
    echo "  $0 /data/conn_projects /data/fmriprep"
    echo ""
    exit 1
fi

PROJECT_DIR="$1"
FMRIPREP_DIR="$2"

# Validate arguments
if [ ! -d "$FMRIPREP_DIR" ]; then
    echo -e "${RED}Error: fMRIprep directory not found: $FMRIPREP_DIR${NC}"
    exit 1
fi

# Create project directory if it doesn't exist
if [ ! -d "$PROJECT_DIR" ]; then
    echo -e "${BLUE}Creating project directory: $PROJECT_DIR${NC}"
    mkdir -p "$PROJECT_DIR"
fi

# Create temporary MATLAB script with paths substituted
TEMP_SCRIPT=$(mktemp)
TEMP_LOG="${PROJECT_DIR}/processing.log"

# Substitute paths in script
sed "s|/path/to/project/directory|${PROJECT_DIR}|g" "$MATLAB_SCRIPT" | \
sed "s|/path/to/fmriprep/dataset|${FMRIPREP_DIR}|g" > "$TEMP_SCRIPT"

# Print header
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  CONN fMRIprep Processing: Import, Smooth & Denoise        ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Project directory:  $PROJECT_DIR"
echo "  fMRIprep directory: $FMRIPREP_DIR"
echo "  MATLAB script:      $MATLAB_SCRIPT"
echo "  Log file:           $TEMP_LOG"
echo ""

# Count subjects
SUBJECT_COUNT=$(find "$FMRIPREP_DIR" -maxdepth 1 -type d -name "sub-*" | wc -l)
echo -e "${BLUE}Data discovery:${NC}"
echo "  Found $SUBJECT_COUNT subjects in fMRIprep directory"
echo ""

# Check if CONN is available
if ! command -v conn &> /dev/null && ! command -v matlab &> /dev/null; then
    echo -e "${RED}Error: Neither CONN nor MATLAB found in PATH${NC}"
    echo "Please ensure CONN environment is loaded: source ~/.bashrc"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

# Determine which runner to use
if command -v conn &> /dev/null; then
    echo -e "${GREEN}Running with CONN standalone...${NC}"
    conn batch "$TEMP_SCRIPT" 2>&1 | tee "$TEMP_LOG"
elif command -v matlab &> /dev/null; then
    echo -e "${GREEN}Running with MATLAB...${NC}"
    matlab -r "run('$TEMP_SCRIPT')" -logfile "$TEMP_LOG"
else
    echo -e "${RED}Error: Could not determine runner (CONN or MATLAB)${NC}"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

# Clean up temp script
rm -f "$TEMP_SCRIPT"

# Print completion message
echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║  Processing Complete!                                      ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

echo ""
echo -e "${BLUE}Output locations:${NC}"
echo "  CONN project:    $PROJECT_DIR/conn_project.mat"
echo "  Denoised data:   $PROJECT_DIR/conn_*/results/denoising/"
echo "  QA plots:        $PROJECT_DIR/conn_*/results/qa/"
echo "  Processing log:  $TEMP_LOG"
echo ""

echo -e "${BLUE}Next steps:${NC}"
echo "  1. Review QA plots: less $TEMP_LOG (or open with CONN GUI)"
echo "  2. Verify preprocessing quality"
echo "  3. Define ROIs or load atlases in CONN"
echo "  4. Run first-level connectivity analyses"
echo "  5. Run second-level group analyses"
echo ""

exit 0
