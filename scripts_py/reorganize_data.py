import os
import shutil
import re
import glob

def reorganize_data(base_dir):
    print(f"Starting reorganization in {base_dir}...")
    
    # 1. Identify and process single-session subjects
    subjects = [d for d in os.listdir(base_dir) if d.startswith('sub-') and os.path.isdir(os.path.join(base_dir, d))]
    
    for sub in subjects:
        sub_path = os.path.join(base_dir, sub)
        sessions = [d for d in os.listdir(sub_path) if d.startswith('ses-') and os.path.isdir(os.path.join(sub_path, d))]
        
        if len(sessions) == 1:
            ses = sessions[0]
            ses_dir = os.path.join(sub_path, ses)
            ses_anat_dir = os.path.join(ses_dir, 'anat')
            sub_anat_dir = os.path.join(sub_path, 'anat')
            
            if not os.path.exists(sub_anat_dir) and os.path.exists(ses_anat_dir):
                print(f"Standardizing single-session subject: {sub}")
                os.makedirs(sub_anat_dir, exist_ok=True)
                
                for f in os.listdir(ses_anat_dir):
                    f_path = os.path.join(ses_anat_dir, f)
                    if not os.path.isfile(f_path):
                        continue
                        
                    if f.endswith('xfm.txt'):
                        continue
                    
                    new_name = f.replace(f"_{ses}_", "_")
                    shutil.move(f_path, os.path.join(sub_anat_dir, new_name))
                
                # Update references in JSONs
                for json_file in glob.glob(os.path.join(sub_anat_dir, "*.json")):
                    with open(json_file, 'r', encoding='utf-8') as file:
                        content = file.read()
                    
                    content = content.replace(f"{ses}/anat/{sub}_{ses}_", f"anat/{sub}_")
                    content = content.replace(f"{sub}_{ses}_", f"{sub}_")
                    
                    with open(json_file, 'w', encoding='utf-8') as file:
                        file.write(content)
                
                # Update HTML reports
                html_file = os.path.join(base_dir, f"{sub}.html")
                if os.path.exists(html_file):
                    with open(html_file, 'r', encoding='utf-8') as file:
                        content = file.read()
                    
                    content = content.replace(f"{sub}/{ses}/anat/{sub}_{ses}_", f"{sub}/anat/{sub}_")
                    content = content.replace(f"{sub}_{ses}_acq-mprage", f"{sub}_acq-mprage")
                    
                    with open(html_file, 'w', encoding='utf-8') as file:
                        file.write(content)

    # 2. Ensure session-specific anatomical transforms
    for root, dirs, files in os.walk(base_dir):
        if os.path.basename(root) == 'anat':
            sub_path = os.path.dirname(root)
            sub = os.path.basename(sub_path)
            
            for f in files:
                if "_ses-" in f and f.endswith("_xfm.txt"):
                    match = re.search(r'ses-([a-zA-Z0-9]+)', f)
                    if match:
                        ses = f"ses-{match.group(1)}"
                        target_ses_anat = os.path.join(sub_path, ses, 'anat')
                        os.makedirs(target_ses_anat, exist_ok=True)
                        
                        print(f"Ensuring co-registration transform is in session folder: {sub}/{ses}")
                        shutil.move(os.path.join(root, f), os.path.join(target_ses_anat, f))
                        
                        # Correct HTML references
                        html_file = os.path.join(base_dir, f"{sub}.html")
                        if os.path.exists(html_file):
                            with open(html_file, 'r', encoding='utf-8') as file:
                                content = file.read()
                            content = content.replace(f"{sub}/anat/{sub}_{ses}_", f"{sub}/{ses}/anat/{sub}_{ses}_")
                            with open(html_file, 'w', encoding='utf-8') as file:
                                file.write(content)
                        
                        # Correct JSON references (walk through sub folder)
                        for r, d, f_list in os.walk(sub_path):
                            for jf in f_list:
                                if jf.endswith(".json"):
                                    json_p = os.path.join(r, jf)
                                    with open(json_p, 'r', encoding='utf-8') as file:
                                        content = file.read()
                                    content = content.replace(f"anat/{sub}_{ses}_", f"{ses}/anat/{sub}_{ses}_")
                                    with open(json_p, 'w', encoding='utf-8') as file:
                                        file.write(content)

    print("Reorganization complete.")

if __name__ == "__main__":
    import sys
    reorganize_data(sys.argv[1] if len(sys.argv) > 1 else os.getcwd())
