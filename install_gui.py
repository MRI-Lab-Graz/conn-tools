import os
import subprocess
import sys
import shutil

def run_command(command):
    print(f"Running: {' '.join(command)}")
    try:
        subprocess.check_call(command)
    except subprocess.CalledProcessError as e:
        print(f"Error occurred: {e}")
        return False
    return True

def main():
    print("--- CONN Tool Manager: Installation via UV ---")
    
    # 1. Check if uv is installed
    uv_path = shutil.which("uv")
    if not uv_path:
        print("Error: 'uv' not found in your PATH.")
        print("Please install uv first: https://github.com/astral-sh/uv")
        print("Quick install (Mac/Linux): curl -LsSf https://astral-sh.uv/install.sh | sh")
        print("Quick install (Windows): powershell -ExecutionPolicy ByPass -c \"ir https://astral-sh.uv/install.ps1 | iex\"")
        sys.exit(1)

    # 2. Setup virtual environment
    print("\nCreating virtual environment...")
    if not run_command([uv_path, "venv"]):
        sys.exit(1)

    # 3. Install requirements
    print("\nInstalling packages via uv...")
    # Determine the correct path to the virtual env's python
    # On Windows it's .venv\Scripts\python.exe, on others .venv/bin/python
    if os.name == 'nt':
        pip_cmd = [uv_path, "pip", "install", "-r", "requirements.txt"]
    else:
        pip_cmd = [uv_path, "pip", "install", "-r", "requirements.txt"]
    
    if not run_command(pip_cmd):
        sys.exit(1)

    print("\n--- Installation Successful! ---")
    print("\nTo start the GUI, run:")
    if os.name == 'nt':
        print("  .venv\\Scripts\\python.exe app.py")
    else:
        print("  ./.venv/bin/python app.py")

if __name__ == "__main__":
    main()
