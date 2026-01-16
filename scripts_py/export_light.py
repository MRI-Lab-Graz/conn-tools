import os
import shutil
import glob

def export_light(project_mat, dest_dir):
    project_mat = os.path.abspath(project_mat)
    dest_dir = os.path.abspath(dest_dir)
    
    if not os.path.isfile(project_mat):
        print(f"Error: Project file {project_mat} not found.")
        return

    project_name = os.path.splitext(os.path.basename(project_mat))[0]
    src_root = os.path.dirname(project_mat)
    project_dir = os.path.join(src_root, project_name)

    if not os.path.isdir(project_dir):
        print(f"Error: Project directory {project_dir} not found.")
        return

    print(f"--- Starting Lightweight Export of CONN Project: {project_name} ---")
    os.makedirs(dest_dir, exist_ok=True)

    # 1. Copy the main .mat file
    print("Copying project file...")
    shutil.copy2(project_mat, dest_dir)

    # 2. Copy structure with exclusions
    dest_project_dir = os.path.join(dest_dir, project_name)
    
    def ignore_files(dir, files):
        rel_dir = os.path.relpath(dir, project_dir)
        ignored = []
        
        # Exclude patterns
        for f in files:
            # Absolute exclusions
            if f == "preprocessing": ignored.append(f)
            if f.endswith(".nii"): ignored.append(f)
            
            # Data folder specific exclusions
            if rel_dir == "data":
                if f.startswith("DATA_Subject") or f.startswith("VV_DATA_") or f.startswith("BA_Subject"):
                    ignored.append(f)
        
        return ignored

    print("Syncing results and ROI data...")
    # Since shutil.copytree requires the dest not to exist, we handle merge manually or clear it
    if os.path.exists(dest_project_dir):
        print("Warning: Destination project folder already exists. Overwriting...")
        shutil.rmtree(dest_project_dir)
        
    shutil.copytree(project_dir, dest_project_dir, ignore=ignore_files)

    print("--- Export Complete ---")

if __name__ == "__main__":
    import sys
    if len(sys.argv) < 3:
        print("Usage: python export_light.py <project.mat> <dest_dir>")
    else:
        export_light(sys.argv[1], sys.argv[2])
