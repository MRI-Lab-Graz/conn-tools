#!/bin/bash

# export_conn_light.sh
# Creates a lightweight copy of a CONN project for second-level analysis on another PC.
# Usage: ./export_conn_light.sh /path/to/project_name.mat /path/to/destination_folder

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <project_file.mat> <destination_directory>"
    exit 1
fi

PROJECT_MAT=$(abspath "$1" 2>/dev/null || echo "$1")
DEST_DIR=$(abspath "$2" 2>/dev/null || echo "$2")

# Function to get absolute path (simple version)
abspath() {
    [[ "$1" = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

PROJECT_MAT=$(abspath "$1")
DEST_DIR=$(abspath "$2")

if [ ! -f "$PROJECT_MAT" ]; then
    echo "Error: Project file $PROJECT_MAT not found."
    exit 1
fi

PROJECT_NAME=$(basename "$PROJECT_MAT" .mat)
SRC_DIR=$(dirname "$PROJECT_MAT")
PROJECT_DIR="$SRC_DIR/$PROJECT_NAME"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory $PROJECT_DIR not found."
    exit 1
fi

echo "--- Starting Lightweight Export of CONN Project: $PROJECT_NAME ---"
echo "Source: $PROJECT_DIR"
echo "Destination: $DEST_DIR"

# Create destination root
mkdir -p "$DEST_DIR"

# 1. Copy the main .mat file
echo "Copying project file..."
cp "$PROJECT_MAT" "$DEST_DIR/"

# 2. Use rsync to copy the folder structure with exclusions
# Exclude: 
# - DATA_*.mat (denoised volumes, very large)
# - VV_DATA_*.mat (voxel-to-voxel data, very large)
# - preprocessing/ (not needed for stats)
# - *.nii files in the data/ folder (usually intermediate files)
echo "Syncing results and ROI data (this may take a few minutes)..."
rsync -av \
    --include="results/" \
    --include="results/firstlevel/" \
    --include="results/firstlevel/**" \
    --include="data/" \
    --include="data/ROI_Subject*.mat" \
    --include="data/COND_Subject*.mat" \
    --include="data/COV_Subject*.mat" \
    --exclude="data/DATA_Subject*.mat" \
    --exclude="data/VV_DATA_*.mat" \
    --exclude="data/BA_Subject*.mat" \
    --exclude="preprocessing/" \
    --exclude="*.nii" \
    "$PROJECT_DIR" "$DEST_DIR/"

echo "--- Export Complete ---"
echo "To use on the new PC:"
echo "1. Move the folder/file to the new machine."
echo "2. Open '$PROJECT_NAME.mat' in CONN."
echo "3. Go to the 'Results (2nd-level)' tab to run your statistics."
