# CONN Standalone Installation Guide

This guide provides instructions for installing CONN standalone (pre-compiled) release on a Linux server without GUI requirements.

## Overview

The `install_conn_standalone.sh` script automates the installation of:
- **CONN** (standalone pre-compiled binary v22a for Linux)
- **MATLAB Compiler Runtime (MCR)** v9.12 (R2022a)
- Environment configuration for easy access

## Prerequisites

Ensure your Linux server has the following installed:
```bash
# Required packages
sudo apt-get install wget curl unzip  # Debian/Ubuntu
# OR
sudo yum install wget curl unzip      # RedHat/CentOS
```

## Download Requirements

CONN and MCR must be downloaded from NITRC before running the installer:

1. **Visit**: http://www.nitrc.org/projects/conn
2. **Download** these two files:
   - `conn22a_glnxa64.zip` (CONN standalone binary)
   - `MCR_R2022a_glnxa64_installer.zip` (MATLAB Compiler Runtime)

## Installation Steps

### Step 1: Run the Installation Script

```bash
# Default installation to ~/conn_standalone
./install_conn_standalone.sh

# OR specify custom installation path
./install_conn_standalone.sh /opt/conn_standalone
```

### Step 2: Place Downloaded Files When Prompted

The script will wait for the downloaded files:
```
Waiting for files to be available...
.....

1. Place conn22a_glnxa64.zip in: /path/to/installation/temp/
2. Place MCR_R2022a_glnxa64_installer.zip in: /path/to/installation/temp/
```

The script will:
- Detect when files are present
- Extract CONN
- Install MCR (may take several minutes)
- Configure environment variables
- Verify the installation

### Step 3: Apply Environment Configuration

After installation completes, apply the environment settings:

```bash
source ~/.bashrc
```

## Usage

### Interactive Mode (with graphics)
```bash
# Load environment and start CONN GUI
source ~/.bashrc
conn
```

### Batch Mode (no graphics needed)
```bash
# Run CONN batch scripts without GUI
source ~/.bashrc
conn batch your_script.m
```

### Remote Access with Graphics
If you need graphics over a remote connection, use VirtualGL:

```bash
# Requires VirtualGL/TurboVNC installation
source ~/.bashrc
vglrun conn
```

## Configuration Details

The installation creates `conn_env.sh` in your installation directory with:

```bash
export PATH=/path/to/installation:$PATH
export MCRROOT=/path/to/installation/MCR/v912
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/runtime/glnxa64
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/bin/glnxa64
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/os/glnxa64
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${MCRROOT}/sys/opengl/lib/glnxa64
export XAPPLRESDIR=${MCRROOT}/X11/app-defaults
export LD_LIBRARY_PATH
```

This is automatically sourced in `~/.bashrc`.

## For System Administrators (Optional)

For multi-user environments, you can use Environment Modules instead of bashrc:

1. **Link the modulefile**:
   ```bash
   ln -s /path/to/installation/modulefile.txt /modules/conn_standalone/R2022a
   ```

2. **Edit the modulefile** and update paths to your installation directory

3. **Load with**:
   ```bash
   module load conn_standalone/R2022a
   conn batch script.m
   ```

## Troubleshooting

### Script waiting for files indefinitely
- Ensure files are placed in the exact `temp/` subdirectory of the installation path
- Files must be named exactly: `conn22a_glnxa64.zip` and `MCR_R2022a_glnxa64_installer.zip`

### MCR Installation Fails
- Verify you have sufficient disk space (~5GB recommended)
- Check write permissions in the installation directory
- Ensure `unzip` is installed

### "conn: command not found"
- Reload bash configuration: `source ~/.bashrc`
- Or launch a new terminal session

### Graphics/OpenGL Issues
- The script includes system OpenGL libraries by default
- For VirtualGL: remove the line with `/sys/opengl/lib/glnxa64` from `conn_env.sh` and install VirtualGL + TurboVNC

## Uninstallation

To uninstall CONN:

```bash
# Remove installation directory
rm -rf /path/to/installation

# Remove environment configuration from bashrc
# Edit ~/.bashrc and remove the lines mentioning conn_env.sh
nano ~/.bashrc
```

## References

- [CONN Official Installation Guide](https://web.conn-toolbox.org/resources/conn-installation/standalone-linux)
- [CONN NITRC Project Page](http://www.nitrc.org/projects/conn)
- [MATLAB Compiler Runtime Documentation](https://www.mathworks.com/products/compiler/mcr.html)

## Support

For issues with CONN installation or usage:
- Visit: http://www.nitrc.org/forum/forum.php?forum_id=1144
- Contact: info@conn-toolbox.org
