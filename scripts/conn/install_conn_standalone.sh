#!/bin/bash
###############################################################################
# CONN Standalone Installation Script for Linux (no GUI required)
# 
# This script automates the installation of CONN pre-compiled standalone
# release and the MATLAB Compiler Runtime (MCR) on Linux.
#
# Usage: ./install_conn_standalone.sh [installation_path]
#        Default installation path: ~/conn_standalone
###############################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration (defaults)
INSTALL_DIR="$HOME/conn_standalone"
CONN_ZIP=""
MCR_ZIP=""
CONN_URL=""
MCR_URL=""

# Parse arguments (supports flags and legacy positional install path)
if [[ $# -gt 0 && "$1" != -* ]]; then
    INSTALL_DIR="$1"
    shift 1
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        -i|--install-dir)
            INSTALL_DIR="$2"
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
        -h|--help)
            cat <<EOF
Usage: $0 [install_path] [options]

Options:
  -i, --install-dir <path>   CONN installation directory (default: ~/conn_standalone)
  --conn-zip <path>          Path to conn22a_glnxa64.zip (optional)
  --mcr-zip <path>           Path to MCR_R2022a_glnxa64_installer.zip (optional)
  --conn-url <url>           Direct download URL for conn22a_glnxa64.zip (optional)
  --mcr-url <url>            Direct download URL for MCR_R2022a_glnxa64_installer.zip (optional)
  -h, --help                 Show this help message

Legacy:
  $0 /path/to/install
EOF
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Derived paths
TEMP_DIR="${INSTALL_DIR}/temp"
MCR_VERSION="R2022a"
MCR_VERSION_NUM="v912"
CONN_VERSION="22a"
CONN_RELEASE_URL="http://www.nitrc.org/projects/conn"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}CONN Standalone Installation Script${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Installation directory: $INSTALL_DIR"
echo "MCR version: $MCR_VERSION (9.12)"
echo "CONN version: $CONN_VERSION"
if [[ -n "$CONN_ZIP" ]]; then
    echo "CONN zip provided: $CONN_ZIP"
fi
if [[ -n "$MCR_ZIP" ]]; then
    echo "MCR zip provided: $MCR_ZIP"
fi
if [[ -n "$CONN_URL" ]]; then
    echo "CONN url provided: $CONN_URL"
fi
if [[ -n "$MCR_URL" ]]; then
    echo "MCR url provided: $MCR_URL"
fi
echo ""

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"
if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
    echo -e "${RED}Error: wget or curl is required but not installed.${NC}"
    exit 1
fi

if ! command -v unzip &> /dev/null; then
    echo -e "${RED}Error: unzip is required but not installed.${NC}"
    exit 1
fi

# Create directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p "$INSTALL_DIR"
mkdir -p "$TEMP_DIR/MCR"

# If zip paths provided, copy them into temp directory
if [[ -n "$CONN_ZIP" ]]; then
    if [ ! -f "$CONN_ZIP" ]; then
        echo -e "${RED}Error: CONN zip not found: $CONN_ZIP${NC}"
        exit 1
    fi
    cp -f "$CONN_ZIP" "$TEMP_DIR/conn${CONN_VERSION}_glnxa64.zip"
fi

if [[ -n "$MCR_ZIP" ]]; then
    if [ ! -f "$MCR_ZIP" ]; then
        echo -e "${RED}Error: MCR zip not found: $MCR_ZIP${NC}"
        exit 1
    fi
    cp -f "$MCR_ZIP" "$TEMP_DIR/MCR_${MCR_VERSION}_glnxa64_installer.zip"
fi

# If URLs provided, download into temp directory
download_file() {
    local url="$1"
    local out="$2"

    if command -v curl &> /dev/null; then
        curl -L --fail -o "$out" "$url"
    elif command -v wget &> /dev/null; then
        wget -O "$out" "$url"
    else
        echo -e "${RED}Error: curl or wget required to download files${NC}"
        exit 1
    fi
}

if [[ -n "$CONN_URL" ]]; then
    echo -e "${YELLOW}Downloading CONN zip...${NC}"
    download_file "$CONN_URL" "$TEMP_DIR/conn${CONN_VERSION}_glnxa64.zip"
fi

if [[ -n "$MCR_URL" ]]; then
    echo -e "${YELLOW}Downloading MCR zip...${NC}"
    download_file "$MCR_URL" "$TEMP_DIR/MCR_${MCR_VERSION}_glnxa64_installer.zip"
fi

# Download files
echo -e "${YELLOW}Downloading CONN and MCR...${NC}"
echo "Note: Files must be downloaded from NITRC. Please visit:"
echo "  $CONN_RELEASE_URL"
echo ""
echo "Download these files and place them in: $TEMP_DIR"
echo "  1. conn${CONN_VERSION}_glnxa64.zip"
echo "  2. MCR_${MCR_VERSION}_glnxa64_installer.zip"
echo ""
echo "Waiting for files to be available..."

# Wait for CONN file
while [ ! -f "$TEMP_DIR/conn${CONN_VERSION}_glnxa64.zip" ]; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN} CONN file found!${NC}"

# Wait for MCR file
while [ ! -f "$TEMP_DIR/MCR_${MCR_VERSION}_glnxa64_installer.zip" ]; do
    echo -n "."
    sleep 2
done
echo -e "${GREEN} MCR file found!${NC}"

# Step 1: Extract CONN
echo ""
echo -e "${YELLOW}Step 1: Extracting CONN...${NC}"
unzip -q "$TEMP_DIR/conn${CONN_VERSION}_glnxa64.zip" -d "$INSTALL_DIR"
echo -e "${GREEN}✓ CONN extracted${NC}"

# Step 2: Extract and install MCR
echo ""
echo -e "${YELLOW}Step 2: Installing MATLAB Compiler Runtime (MCR)...${NC}"
echo "This may take several minutes..."
unzip -q "$TEMP_DIR/MCR_${MCR_VERSION}_glnxa64_installer.zip" -d "$TEMP_DIR/MCR"
sh "$TEMP_DIR/MCR/install" -mode silent -destinationFolder "$INSTALL_DIR/MCR" -agreeToLicense yes
echo -e "${GREEN}✓ MCR installed${NC}"

# Step 3: Configure environment variables
echo ""
echo -e "${YELLOW}Step 3: Configuring environment variables...${NC}"

# Check if .bashrc exists, if not create it
if [ ! -f ~/.bashrc ]; then
    touch ~/.bashrc
fi

# Create a new sourcing file to avoid duplication
BASHRC_APPEND="$INSTALL_DIR/conn_env.sh"

cat > "$BASHRC_APPEND" << 'ENVEOF'
# CONN Standalone Environment Configuration
export PATH=INSTALL_DIR_PLACEHOLDER:$PATH
export MCRROOT=INSTALL_DIR_PLACEHOLDER/MCR/MCR_VERSION_NUM_PLACEHOLDER
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/runtime/glnxa64
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64
export XAPPLRESDIR=${MCRROOT}/X11/app-defaults
export LD_LIBRARY_PATH
ENVEOF

# Replace placeholders
sed -i "s|INSTALL_DIR_PLACEHOLDER|$INSTALL_DIR|g" "$BASHRC_APPEND"
sed -i "s|MCR_VERSION_NUM_PLACEHOLDER|$MCR_VERSION_NUM|g" "$BASHRC_APPEND"

# Add source command to bashrc if not already present
if ! grep -q "source.*conn_env.sh" ~/.bashrc; then
    echo "" >> ~/.bashrc
    echo "# Load CONN environment" >> ~/.bashrc
    echo "[ -f \"$BASHRC_APPEND\" ] && source \"$BASHRC_APPEND\"" >> ~/.bashrc
fi

echo -e "${GREEN}✓ Environment configured${NC}"

# Verify installation
echo ""
echo -e "${YELLOW}Step 4: Verifying installation...${NC}"

if [ -d "$INSTALL_DIR/MCR/$MCR_VERSION_NUM" ]; then
    echo -e "${GREEN}✓ MCR installation verified${NC}"
else
    echo -e "${RED}✗ MCR installation failed${NC}"
    exit 1
fi

if [ -f "$INSTALL_DIR/conn" ]; then
    echo -e "${GREEN}✓ CONN executable found${NC}"
else
    echo -e "${RED}✗ CONN executable not found${NC}"
    exit 1
fi

# Cleanup
echo ""
echo -e "${YELLOW}Cleaning up temporary files...${NC}"
rm -rf "$TEMP_DIR"
echo -e "${GREEN}✓ Cleaned up${NC}"

# Final instructions
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Installation directory: $INSTALL_DIR"
echo ""
echo "To start using CONN:"
echo "  1. Source the environment configuration:"
echo "     source ~/.bashrc"
echo ""
echo "  2. Run CONN:"
echo "     conn"
echo ""
echo "  3. Or run CONN in batch mode (no GUI needed):"
echo "     conn batch your_script.m"
echo ""
echo "For remote access with graphics:"
echo "  vglrun conn"
echo ""
echo "Environment configuration saved in: $BASHRC_APPEND"
echo ""
