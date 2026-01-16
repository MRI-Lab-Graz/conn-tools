# CONN Tool Manager

A lightweight, cross-platform GUI designed for fMRI researchers using the CONN toolbox and fMRIPrep. This tool simplifies data reorganization, participant ID mapping, and lightweight project exporting for second-level analysis.

## 🚀 Key Features

*   **Reorganize Data**: Standardizes fMRIPrep output across single and multi-session subjects to ensure CONN compatibility.
*   **Map CONN IDs**: Automatically maps BIDS `sub-<label>` IDs to CONN's internal `subject 1, 2, 3...` IDs by parsing project logs.
*   **Lightweight Export**: Creates a "portable" version of your CONN project by excluding heavy denoised functional volumes (`DATA_*.mat`), allowing you to perform second-level statistics on a laptop without moving hundreds of GBs.
*   **Cross-Platform GUI**: Built with Flask and Waitress, running in your web browser with a built-in terminal for status tracking.
*   **Standalone Build**: Can be compiled into a single executable for Windows, macOS, and Linux.

## 🛠 Installation (Developer Mode)

1.  **Install dependencies**:
    Make sure you have [uv](https://github.com/astral-sh/uv) installed for the fastest setup.
    ```bash
    python install_gui.py
    ```

2.  **Run the application**:
    ```bash
    # macOS/Linux
    ./.venv/bin/python app.py

    # Windows
    .venv\Scripts\python.exe app.py
    ```

## 📦 Standalone Downloads

If you are using a version downloaded from the [GitHub Releases](https://github.com/MRI-Lab-Graz/conn-tools/releases) page, simply extract the file and run it. No Python installation is required.

## 📋 Usage Guide

### 1. Reorganize Data
Point the tool to your BIDS root directory. It will ensure that anatomical files are correctly placed and JSON/HTML references are updated so CONN can find your data consistently.

### 2. Map IDs
Select your `conn_project.mat` and your BIDS folder. The tool will generate a `participants_with_conn.tsv` file containing the mapping between your BIDS IDs and CONN subject indices.

### 3. Lightweight Export
Perfect for moving projects.
*   **Source**: Your main `.mat` file.
*   **Destination**: A new folder (e.g., on a portable drive).
*   **Result**: A project containing only first-level results and ROI data, optimized for group statistics.

## 🔬 Lab Information

Developed for the **MRI Lab Graz**.

*   **GitHub**: [https://github.com/MRI-Lab-Graz/](https://github.com/MRI-Lab-Graz/)
*   **Maintainer**: Karl (MRI Lab Graz)

---
*Disclaimer: This tool is not an official part of the CONN toolbox. Always back up your data before performing batch reorganization.*
