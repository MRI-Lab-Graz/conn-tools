#!/bin/bash
################################################################################
# CONN Modular Pipeline Wrapper
#
# Runs all 4 steps of the CONN processing pipeline:
# 1. Project setup
# 2. fMRIprep data import
# 3. Spatial smoothing
# 4. Denoising
#
# Usage:
#   ./run_conn_pipeline.sh <project_dir> <fmriprep_dir> [options]
#
# Example:
#   ./run_conn_pipeline.sh /data/conn_project /data/fmriprep
#
# Options:
#   --skip-setup      Skip Step 1 (project already exists)
#   --skip-import     Skip Step 2
#   --skip-smooth     Skip Step 3 (no smoothing)
#   --skip-denoise    Skip Step 4
#   --fwhm <mm>       Set smoothing FWHM (default: 8)
#   --no-qa           Skip QA plots in Step 4
#
################################################################################

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Default options
SKIP_SETUP=false
SKIP_IMPORT=false
SKIP_SMOOTH=false
SKIP_DENOISE=false
SMOOTHING_FWHM=8
GENERATE_QA=true
CONN_INSTALL_DIR="$HOME/conn_standalone"
CONN_ZIP=""
MCR_ZIP=""
CONN_URL=""
MCR_URL=""
PROJECT_DIR=""
FMRIPREP_DIR=""
BIDS_DIR=""

# Parse arguments
if [ $# -eq 0 ]; then
    cat <<EOF
${RED}Error: Missing arguments${NC}

Usage: $0 -p <project_dir> -f <fmriprep_dir> -b <bids_dir> [options]

Required Arguments:
  -p, --project-dir <path>     Directory where CONN project will be created/saved
  -f, --fmriprep-dir <path>    Root directory of fMRIprep preprocessed data
  -b, --bids-dir <path>        Root directory of BIDS dataset (used to extract TR, subject count, etc.)

Optional Arguments:
  -i, --install-dir <path>     CONN installation directory (default: ~/conn_standalone)
    --conn-zip <path>            Path to conn22a_glnxa64.zip (optional)
    --mcr-zip <path>             Path to MCR_R2022a_glnxa64_installer.zip (optional)
    --conn-url <url>             Direct download URL for conn22a_glnxa64.zip (optional)
    --mcr-url <url>              Direct download URL for MCR_R2022a_glnxa64_installer.zip (optional)
  --skip-setup                 Skip Step 1 (project already exists)
  --skip-import                Skip Step 2 (data already imported)
  --skip-smooth                Skip Step 3 (no smoothing)
  --skip-denoise               Skip Step 4 (no denoising)
  --fwhm <mm>                  Smoothing kernel size (default: 8 mm)
  --no-qa                      Do not generate QA plots
  -h, --help                   Show this help message

Examples:
  $0 -p /data/conn_project -f /data/fmriprep -b /data/bids
  $0 -p /data/conn_project -f /data/fmriprep -b /data/bids -i /opt/conn
    $0 -p /data/conn_project -f /data/fmriprep -b /data/bids --conn-zip ~/Downloads/conn22a_glnxa64.zip --mcr-zip ~/Downloads/MCR_R2022a_glnxa64_installer.zip
    $0 -p /data/conn_project -f /data/fmriprep -b /data/bids --conn-url <url> --mcr-url <url>
  $0 -p /data/conn_project -f /data/fmriprep -b /data/bids --fwhm 6 --no-qa
  $0 -p /data/conn_project -f /data/fmriprep -b /data/bids --skip-smooth

Legacy Usage (still supported):
  $0 <project_dir> <fmriprep_dir> [options]

EOF
    exit 1
fi

# Check for legacy positional arguments (backwards compatibility)
if [[ "$1" != -* ]]; then
    # Legacy mode: positional arguments
    PROJECT_DIR="$1"
    FMRIPREP_DIR="$2"
    shift 2
fi

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project-dir)
            PROJECT_DIR="$2"
            shift 2
            ;;
        -f|--fmriprep-dir)
            FMRIPREP_DIR="$2"
            shift 2
            ;;
        -b|--bids-dir)
            BIDS_DIR="$2"
            shift 2
            ;;
        -i|--install-dir)
            CONN_INSTALL_DIR="$2"
            shift 2
            ;;
        --conn-zip)
            CONN_ZIP="$2"
            shift 2
            ;;
        --mcr-zip)
            MCR_ZIP="$2"
            shift 2
            ;;
        --conn-url)
            CONN_URL="$2"
            shift 2
            ;;
        --mcr-url)
            MCR_URL="$2"
            shift 2
            ;;
        --skip-setup)
            SKIP_SETUP=true
            shift
            ;;
        --skip-import)
            SKIP_IMPORT=true
            shift
            ;;
        --skip-smooth)
            SKIP_SMOOTH=true
            shift
            ;;
        --skip-denoise)
            SKIP_DENOISE=true
            shift
            ;;
        --fwhm)
            SMOOTHING_FWHM="$2"
            shift 2
            ;;
        --no-qa)
            GENERATE_QA=false
            shift
            ;;
        -h|--help)
            # Help message already shown above
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$PROJECT_DIR" ]]; then
    echo -e "${RED}Error: Project directory (-p/--project-dir) is required${NC}"
    echo "Use -h or --help for usage information"
    exit 1
fi

if [[ -z "$FMRIPREP_DIR" ]]; then
    echo -e "${RED}Error: fMRIprep directory (-f/--fmriprep-dir) is required${NC}"
    echo "Use -h or --help for usage information"
    exit 1
fi

if [[ -z "$BIDS_DIR" ]]; then
    echo -e "${RED}Error: BIDS directory (-b/--bids-dir) is required${NC}"
    echo "Use -h or --help for usage information"
    exit 1
fi

# Validate paths
if [ ! -d "$FMRIPREP_DIR" ]; then
    echo -e "${RED}Error: fMRIprep directory not found: $FMRIPREP_DIR${NC}"
    exit 1
fi

if [ ! -d "$BIDS_DIR" ]; then
    echo -e "${RED}Error: BIDS directory not found: $BIDS_DIR${NC}"
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
fi

# Log file
LOG_FILE="${PROJECT_DIR}/conn_pipeline.log"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Print header
echo -e "${GREEN}"
cat <<'EOF'
╔════════════════════════════════════════════════════════════════╗
║           CONN Modular Processing Pipeline                     ║
║  Project Setup → Import → Smooth → Denoise                     ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Project directory:  $PROJECT_DIR"
echo "  fMRIprep directory: $FMRIPREP_DIR"
echo "  BIDS directory:     $BIDS_DIR"
echo "  CONN install dir:   $CONN_INSTALL_DIR"
if [[ -n "$CONN_ZIP" ]]; then
    echo "  CONN zip:           $CONN_ZIP"
fi
if [[ -n "$MCR_ZIP" ]]; then
    echo "  MCR zip:            $MCR_ZIP"
fi
if [[ -n "$CONN_URL" ]]; then
    echo "  CONN url:           $CONN_URL"
fi
if [[ -n "$MCR_URL" ]]; then
    echo "  MCR url:            $MCR_URL"
fi
echo "  Smoothing FWHM:     $SMOOTHING_FWHM mm"
echo "  Generate QA:        $GENERATE_QA"
echo "  Log file:           $LOG_FILE"
echo ""

# Extract BIDS metadata
echo -e "${CYAN}Extracting metadata from BIDS dataset...${NC}"
BIDS_METADATA_FILE=$(mktemp)
if python3 "$SCRIPT_DIR/../scripts_py/read_bids_metadata.py" "$BIDS_DIR" --json > "$BIDS_METADATA_FILE" 2>&1; then
    BIDS_METADATA=$(cat "$BIDS_METADATA_FILE")
    
    if [ -z "$BIDS_METADATA" ]; then
        echo -e "${YELLOW}Warning: BIDS metadata extraction returned empty${NC}"
        echo "Proceeding with defaults..."
        BIDS_NUM_SUBJECTS=30
        BIDS_TR=2.0
    else
        # Parse JSON output
        BIDS_NUM_SUBJECTS=$(echo "$BIDS_METADATA" | python3 -c "import sys, json; data=json.load(sys.stdin); print(int(data.get('num_subjects', 30)))" 2>/dev/null)
        BIDS_TR=$(echo "$BIDS_METADATA" | python3 -c "import sys, json; data=json.load(sys.stdin); print(float(data.get('tr', 2.0)))" 2>/dev/null)
        
        if [ -z "$BIDS_NUM_SUBJECTS" ] || [ -z "$BIDS_TR" ]; then
            echo -e "${YELLOW}Warning: Could not parse BIDS metadata${NC}"
            echo "Proceeding with defaults..."
            BIDS_NUM_SUBJECTS=30
            BIDS_TR=2.0
        else
            echo -e "${GREEN}✓ BIDS metadata extracted:${NC}"
            echo "    Subjects: $BIDS_NUM_SUBJECTS"
            echo "    TR: $BIDS_TR seconds"
        fi
    fi
else
    echo -e "${YELLOW}Warning: Could not extract BIDS metadata${NC}"
    echo "Proceeding with defaults..."
    BIDS_NUM_SUBJECTS=30
    BIDS_TR=2.0
fi
rm -f "$BIDS_METADATA_FILE"
echo ""

# Count subjects
SUBJ_COUNT=$(find "$FMRIPREP_DIR" -maxdepth 1 -type d -name "sub-*" | wc -l)
echo "  Found $SUBJ_COUNT subjects in fMRIprep directory"
echo ""

# Check CONN availability - install if not found
if ! command -v conn &> /dev/null && ! command -v matlab &> /dev/null; then
    # Try loading environment from install dir if present
    if [ -f "$CONN_INSTALL_DIR/conn_env.sh" ]; then
        echo -e "${BLUE}Loading CONN environment from $CONN_INSTALL_DIR/conn_env.sh...${NC}"
        source "$CONN_INSTALL_DIR/conn_env.sh"
    fi

    # Re-check after sourcing
    if command -v conn &> /dev/null || command -v matlab &> /dev/null; then
        echo -e "${GREEN}CONN found after loading environment.${NC}"
    else
    echo -e "${YELLOW}CONN not found in PATH${NC}"
    echo ""
    
    # Check if installation script exists
    INSTALL_SCRIPT="${SCRIPT_DIR}/install_conn_standalone.sh"
    if [ -f "$INSTALL_SCRIPT" ]; then
        echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
        echo -e "${BLUE}           CONN Installation Required                   ${NC}"
        echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
        echo ""
        echo "CONN will be installed to: $CONN_INSTALL_DIR"
        echo ""
        echo -e "${YELLOW}Note: Installation requires manual download of files from NITRC:${NC}"
        echo "  1. conn22a_glnxa64.zip"
        echo "  2. MCR_R2022a_glnxa64_installer.zip"
        echo ""
        echo "The installation script will guide you through the process."
        echo ""
        read -p "Install CONN now? [Y/n] " -n 1 -r
        echo ""
        
        if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
            echo ""
            echo -e "${GREEN}Starting CONN installation...${NC}"
            echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
            echo ""
            
            INSTALL_ARGS=("--install-dir" "$CONN_INSTALL_DIR")
            if [[ -n "$CONN_ZIP" ]]; then
                INSTALL_ARGS+=("--conn-zip" "$CONN_ZIP")
            fi
            if [[ -n "$MCR_ZIP" ]]; then
                INSTALL_ARGS+=("--mcr-zip" "$MCR_ZIP")
            fi
            if [[ -n "$CONN_URL" ]]; then
                INSTALL_ARGS+=("--conn-url" "$CONN_URL")
            fi
            if [[ -n "$MCR_URL" ]]; then
                INSTALL_ARGS+=("--mcr-url" "$MCR_URL")
            fi
            bash "$INSTALL_SCRIPT" "${INSTALL_ARGS[@]}"
            INSTALL_EXIT=$?
            
            if [ $INSTALL_EXIT -ne 0 ]; then
                echo ""
                echo -e "${RED}Installation failed or was cancelled${NC}"
                echo "To install CONN manually later, run:"
                echo "  bash $INSTALL_SCRIPT $CONN_INSTALL_DIR"
                echo "  source ~/.bashrc"
                exit 1
            fi
            
            # Source bashrc to load environment
            echo ""
            echo -e "${BLUE}Loading CONN environment...${NC}"
            if [ -f ~/.bashrc ]; then
                source ~/.bashrc
            fi
            
            # Check again
            if ! command -v conn &> /dev/null && ! command -v matlab &> /dev/null; then
                echo -e "${YELLOW}CONN installed but not yet in PATH${NC}"
                echo "Please run in a new terminal:"
                echo "  source ~/.bashrc"
                echo "  bash $0 $@"
                exit 0
            fi
            
            echo -e "${GREEN}✓ CONN installed and loaded successfully${NC}"
            echo ""
        else
            echo ""
            echo -e "${YELLOW}Installation cancelled${NC}"
            echo ""
            echo "To continue without installation:"
            echo "  1. Install CONN manually: bash $INSTALL_SCRIPT ~/conn_standalone"
            echo "  2. Load environment: source ~/.bashrc"
            echo "  3. Re-run this script"
            exit 0
        fi
    else
        echo -e "${RED}Error: CONN installation script not found${NC}"
        echo "Expected location: $INSTALL_SCRIPT"
        echo ""
        echo "Please install CONN manually or ensure the installation script is present."
        exit 1
    fi
    fi
fi

if command -v conn &> /dev/null; then
    RUNNER="conn batch"
    echo -e "${GREEN}Using CONN standalone${NC}"
elif command -v matlab &> /dev/null; then
    RUNNER="matlab -r"
    echo -e "${GREEN}Using MATLAB${NC}"
fi
echo ""

# Helper function to run scripts
run_step() {
    local step_num=$1
    local step_name=$2
    local script_file=$3
    local skip=$4

    if [ "$skip" = true ]; then
        echo -e "${YELLOW}Skipping Step $step_num: $step_name${NC}"
        echo ""
        return 0
    fi

    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}Step $step_num: $step_name${NC}"
    echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"

    if [ ! -f "$SCRIPT_DIR/$script_file" ]; then
        echo -e "${RED}Error: Script not found: $SCRIPT_DIR/$script_file${NC}"
        exit 1
    fi

    # Create temporary script with substituted paths and parameters
    TEMP_SCRIPT=$(mktemp -p "$SCRIPT_DIR" "conn_batch_tmp_${step_num}_XXXXXX.m")
    sed "s|/path/to/project/directory|${PROJECT_DIR}|g" "$SCRIPT_DIR/$script_file" | \
    sed "s|/path/to/fmriprep/dataset|${FMRIPREP_DIR}|g" | \
    sed "s|/path/to/bids/dataset|${BIDS_DIR}|g" | \
    sed "s|NSUBJECTS           = [0-9]*;|NSUBJECTS           = ${BIDS_NUM_SUBJECTS};|g" | \
    sed "s|REPETITION_TIME     = [0-9.]*;|REPETITION_TIME     = ${BIDS_TR};|g" | \
    sed "s|VOLUME_SMOOTHING_FWHM    = [0-9]*|VOLUME_SMOOTHING_FWHM    = ${SMOOTHING_FWHM}|g" | \
    sed "s|GENERATE_QA_PLOTS = true|GENERATE_QA_PLOTS = ${GENERATE_QA}|g" > "$TEMP_SCRIPT"

    # Create output file to capture errors
    STEP_OUTPUT=$(mktemp)
    
    # Run script and capture output
    if [[ "$RUNNER" == *"conn"* ]]; then
        TEMP_DIR=$(dirname "$TEMP_SCRIPT")
        TEMP_BASE=$(basename "$TEMP_SCRIPT")
        ( cd "$TEMP_DIR" && $RUNNER "$TEMP_BASE" ) > "$STEP_OUTPUT" 2>&1
        STEP_EXIT=$?
    else
        $RUNNER "run('$TEMP_SCRIPT'); quit;" > "$STEP_OUTPUT" 2>&1
        STEP_EXIT=$?
    fi
    
    # Print captured output
    cat "$STEP_OUTPUT"
    
    # Check for errors in output (MATLAB errors contain "Error in" or "ERROR DESCRIPTION")
    if grep -q "ERROR DESCRIPTION\|Error in\|Brace indexing\|Invalid use of operator" "$STEP_OUTPUT"; then
        echo ""
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}✗ Step $step_num FAILED: $step_name${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        rm -f "$TEMP_SCRIPT" "$STEP_OUTPUT"
        exit 1
    fi
    
    # Also check exit code
    if [ $STEP_EXIT -ne 0 ]; then
        echo ""
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${RED}✗ Step $step_num FAILED: $step_name (exit code: $STEP_EXIT)${NC}"
        echo -e "${RED}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        rm -f "$TEMP_SCRIPT" "$STEP_OUTPUT"
        exit 1
    fi

    rm -f "$TEMP_SCRIPT" "$STEP_OUTPUT"
    echo -e "${GREEN}✓ Step $step_num completed successfully${NC}"
    echo ""
}

# Run pipeline
START_TIME=$(date +%s)

run_step 1 "Project Setup" "batch_conn_01_project_setup.m" "$SKIP_SETUP"
run_step 2 "fMRIprep Import" "batch_conn_02_import_fmriprep.m" "$SKIP_IMPORT"
run_step 3 "Spatial Smoothing" "batch_conn_03_smooth.m" "$SKIP_SMOOTH"
run_step 4 "Denoising" "batch_conn_04_denoise.m" "$SKIP_DENOISE"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))
SECONDS=$((DURATION % 60))

# Print summary
echo -e "${GREEN}"
cat <<'EOF'
╔════════════════════════════════════════════════════════════════╗
║                   Pipeline Complete!                           ║
╚════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo ""
echo -e "${BLUE}Processing Summary:${NC}"
echo "  Total time: ${HOURS}h ${MINUTES}m ${SECONDS}s"
echo "  Subjects processed: $SUBJ_COUNT"
echo ""

echo -e "${BLUE}Output Locations:${NC}"
echo "  CONN project:      $PROJECT_DIR/conn_project.mat"
echo "  Preprocessed data: $PROJECT_DIR/conn_*/results/"
echo "  Denoised BOLD:     $PROJECT_DIR/conn_*/results/denoising/"
if [ "$GENERATE_QA" = true ]; then
    echo "  QA plots:          $PROJECT_DIR/conn_*/results/qa/"
fi
echo "  Log file:          $LOG_FILE"
echo ""

echo -e "${BLUE}Next Steps:${NC}"
echo "  1. Review QA plots to assess data quality"
echo "  2. Define ROIs or load standard atlases"
echo "  3. Run first-level connectivity analyses"
echo "  4. Run second-level group-level analyses"
echo ""

echo -e "${BLUE}Documentation:${NC}"
echo "  See MODULAR_PIPELINE_GUIDE.md for detailed instructions"
echo ""

exit 0
