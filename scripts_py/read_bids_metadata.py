#!/usr/bin/env python3
"""
BIDS Metadata Reader
Extracts TR, number of subjects, and other acquisition parameters from BIDS dataset.
"""

import os
import json
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Optional
import glob

class BIDSMetadataReader:
    """Read and extract metadata from BIDS datasets"""
    
    def __init__(self, bids_dir: str):
        """
        Initialize BIDS metadata reader
        
        Args:
            bids_dir: Path to BIDS root directory
        """
        self.bids_dir = Path(bids_dir)
        if not self.bids_dir.exists():
            raise FileNotFoundError(f"BIDS directory not found: {bids_dir}")
        
        self.dataset_description_path = self.bids_dir / "dataset_description.json"
        self._validate_bids_structure()
    
    def _validate_bids_structure(self):
        """Check if directory looks like a BIDS dataset"""
        if not self.dataset_description_path.exists():
            # Not a hard requirement, but warn the user
            print(f"Warning: No dataset_description.json found in {self.bids_dir}", 
                  file=sys.stderr)
    
    def get_subjects(self) -> List[str]:
        """
        Get list of subject IDs in BIDS format (sub-XXXX)
        
        Returns:
            List of subject IDs
        """
        subjects = set()
        
        # Look for sub-* directories
        for item in self.bids_dir.iterdir():
            if item.is_dir() and item.name.startswith('sub-'):
                subjects.add(item.name)
        
        return sorted(list(subjects))
    
    def get_number_of_subjects(self) -> int:
        """
        Get the number of subjects in the dataset
        
        Returns:
            Number of subjects
        """
        return len(self.get_subjects())
    
    def get_tr_from_json_files(self) -> Optional[float]:
        """
        Extract TR (RepetitionTime) from functional JSON sidecars
        
        Returns:
            TR in seconds (float) or None if not found
        """
        # Search for *_bold.json files (functional data)
        json_files = list(self.bids_dir.rglob("*_bold.json"))
        
        if not json_files:
            return None
        
        # Read the first one found
        try:
            with open(json_files[0], 'r') as f:
                data = json.load(f)
                if 'RepetitionTime' in data:
                    return float(data['RepetitionTime'])
        except (json.JSONDecodeError, IOError, KeyError):
            pass
        
        return None
    
    def get_acquisition_parameters(self) -> Dict:
        """
        Extract all relevant acquisition parameters from BIDS
        
        Returns:
            Dictionary with acquisition parameters
        """
        parameters = {
            'num_subjects': self.get_number_of_subjects(),
            'subjects': self.get_subjects(),
            'tr': self.get_tr_from_json_files(),
        }
        
        # Try to extract from dataset_description.json
        if self.dataset_description_path.exists():
            try:
                with open(self.dataset_description_path, 'r') as f:
                    desc = json.load(f)
                    parameters['name'] = desc.get('Name', 'BIDS Dataset')
                    parameters['dataset_type'] = desc.get('DatasetType', 'raw')
            except (json.JSONDecodeError, IOError):
                pass
        
        # Get number of sessions (if any)
        sessions = set()
        for subject_dir in self.bids_dir.glob("sub-*"):
            for item in subject_dir.iterdir():
                if item.is_dir() and item.name.startswith('ses-'):
                    sessions.add(item.name)
        parameters['sessions'] = sorted(list(sessions))
        
        # Count functional runs
        bold_count = len(list(self.bids_dir.rglob("*_bold.nii*")))
        parameters['num_functional_files'] = bold_count
        
        return parameters
    
    def print_summary(self):
        """Print a summary of BIDS dataset"""
        params = self.get_acquisition_parameters()
        
        print("\n" + "="*60)
        print("BIDS DATASET SUMMARY")
        print("="*60)
        print(f"Dataset Name: {params.get('name', 'Unknown')}")
        print(f"Dataset Type: {params.get('dataset_type', 'Unknown')}")
        print(f"Number of Subjects: {params['num_subjects']}")
        
        if params['subjects']:
            print(f"Subject IDs: {', '.join(params['subjects'][:5])}", end="")
            if len(params['subjects']) > 5:
                print(f", ... (+{len(params['subjects']) - 5} more)")
            else:
                print()
        
        if params['sessions']:
            print(f"Sessions: {', '.join(params['sessions'])}")
        
        if params['tr']:
            print(f"TR (RepetitionTime): {params['tr']:.2f} seconds")
        else:
            print("TR (RepetitionTime): Not found in metadata")
        
        print(f"Functional Files: {params['num_functional_files']}")
        print("="*60 + "\n")
        
        return params


def extract_bids_metadata(bids_dir: str) -> Dict:
    """
    Main function to extract BIDS metadata
    
    Args:
        bids_dir: Path to BIDS root directory
    
    Returns:
        Dictionary with extracted metadata
    """
    try:
        reader = BIDSMetadataReader(bids_dir)
        return reader.get_acquisition_parameters()
    except Exception as e:
        print(f"Error reading BIDS metadata: {e}", file=sys.stderr)
        return {}


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python read_bids_metadata.py <bids_directory> [--json]")
        print("\nExample:")
        print("  python read_bids_metadata.py /data/bids_dataset")
        print("  python read_bids_metadata.py /data/bids_dataset --json")
        sys.exit(1)
    
    bids_dir = sys.argv[1]
    output_json = '--json' in sys.argv
    
    try:
        reader = BIDSMetadataReader(bids_dir)
        params = reader.get_acquisition_parameters()
        
        if output_json:
            # Output as JSON for easy parsing in bash/MATLAB
            print(json.dumps(params, indent=2))
        else:
            # Print human-readable summary
            reader.print_summary()
            print("JSON Output:")
            print(json.dumps(params, indent=2))
    
    except FileNotFoundError as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
