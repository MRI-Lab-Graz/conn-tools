#!/usr/bin/env python3
import argparse
import os
import re
import csv
import sys

def run_mapping(conn_path, bids_dir):
    conn_mat = os.path.abspath(conn_path)
    bids_dir = os.path.abspath(bids_dir)
    
    if not os.path.exists(conn_mat):
        print(f"Error: CONN project file not found: {conn_mat}")
        return
        
    if not os.path.exists(bids_dir):
        print(f"Error: BIDS directory not found: {bids_dir}")
        return
        
    # CONN log file is usually in a directory with the same name as the .mat file (without .mat)
    conn_name = os.path.splitext(os.path.basename(conn_mat))[0]
    conn_dir = os.path.dirname(conn_mat)
    log_path = os.path.join(conn_dir, conn_name, 'logfile.txt')
    
    if not os.path.exists(log_path):
        print(f"Error: CONN log file not found at expected location: {log_path}")
        return
        
    participants_tsv = os.path.join(bids_dir, 'participants.tsv')
    if not os.path.exists(participants_tsv):
        print(f"Error: participants.tsv not found in {bids_dir}")
        return
        
    # 1. Parse log file for mapping
    # Searching for: "functional ...sub-134001... imported to subject 1 session 1"
    mapping = {}
    print(f"Reading log file: {log_path}")
    with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line in f:
            # Match both sub-[0-9]+ and subject [0-9]+
            match = re.search(r'sub-([A-Za-z0-9]+).*imported to subject ([0-9]+)', line)
            if match:
                bids_id = 'sub-' + match.group(1)
                conn_id = match.group(2)
                mapping[bids_id] = conn_id

    if not mapping:
        print("Warning: No mappings found in log file. Check if data import is logged correctly.")
    else:
        print(f"Found {len(mapping)} participant mappings.")

    # 2. Read participants.tsv and add/update conn_id
    output_rows = []
    
    print(f"Reading BIDS participants: {participants_tsv}")
    with open(participants_tsv, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        if not lines:
            print("Error: participants.tsv is empty.")
            return
            
        header = lines[0].strip().split('\t')
        conn_id_idx = -1
        if 'conn_id' in header:
            conn_id_idx = header.index('conn_id')
            print("Note: 'conn_id' column already exists. Updating values.")
        else:
            header.append('conn_id')
            
        for line in lines[1:]:
            parts = line.strip().split('\t')
            if not parts:
                continue
            
            participant_id = parts[0]
            conn_id = mapping.get(participant_id, 'n/a')
            
            if conn_id_idx != -1:
                # Update existing column
                if len(parts) > conn_id_idx:
                    parts[conn_id_idx] = conn_id
                else:
                    # Pad if row was shorter than header
                    while len(parts) < conn_id_idx:
                        parts.append('n/a')
                    parts.append(conn_id)
            else:
                # Append new column
                # Ensure the row has enough columns for the padding if needed
                while len(parts) < len(header) - 1:
                    parts.append('n/a')
                parts.append(conn_id)
                
            output_rows.append('\t'.join(parts))

    # 3. Save to CONN folder
    output_filename = 'participants_with_conn.tsv'
    output_path = os.path.join(conn_dir, output_filename)
    
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\t'.join(header) + '\n')
        for row in output_rows:
            f.write(row + '\n')
            
    print(f"Successfully saved updated participants list to: {output_path}")

def main():
    parser = argparse.ArgumentParser(description='Map BIDS participant IDs to CONN subject IDs.')
    parser.add_argument('-conn', required=True, help='Path to the CONN project .mat file')
    parser.add_argument('-bids', required=True, help='Path to the BIDS folder (containing participants.tsv)')
    
    args = parser.parse_args()
    run_mapping(args.conn, args.bids)

if __name__ == '__main__':
    main()
