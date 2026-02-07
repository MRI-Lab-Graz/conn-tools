%% CONN Batch Script: Import fMRIprep Data (Step 2 of 4)
%
% This script imports preprocessed fMRIprep data into an existing CONN project.
% Supports both single-session and multi-session studies.
%
% REQUIREMENTS:
% - Existing CONN project (created with batch_conn_01_project_setup.m)
% - fMRIprep preprocessed data (space-MNI152NLin2009cAsym or custom)
%
% USAGE:
%   From MATLAB: batch_conn_02_import_fmriprep
%   From command-line: conn batch batch_conn_02_import_fmriprep.m
%
% DATA DISCOVERY:
% Automatically finds files matching:
%   Structurals: sub-*/anat/*space-MNI152NLin2009cAsym*T1w.nii.gz
%   Functionals: sub-*/func/*space-MNI152NLin2009cAsym*desc-preproc_bold.nii.gz
%   (or sessions: sub-*/ses-*/func/...)
%
% NEXT STEP:
%   Run batch_conn_03_smooth.m to apply spatial smoothing
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% USER CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Project
PROJECT_DIR     = '/path/to/project/directory'; % Must match batch_conn_01
PROJECT_FILE    = 'conn_project.mat';           % Project filename

% fMRIprep data
FMRIPREP_DIR    = '/path/to/fmriprep/dataset'; % Root fMRIprep directory
BIDS_SPACE      = 'MNI152NLin2009cAsym';       % Standard space used by fMRIprep
USE_LOCAL_COPY  = 0;                           % 1: Copy files to project; 0: Use original files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DATA DISCOVERY AND IMPORT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n============================================\n');
fprintf('CONN Data Import: fMRIprep (Step 2/4)\n');
fprintf('============================================\n\n');

% Load existing project
project_path = fullfile(PROJECT_DIR, PROJECT_FILE);
if ~isfile(project_path)
    error('Project file not found: %s\nRun batch_conn_01_project_setup.m first.', project_path);
end

fprintf('Loading project: %s\n', project_path);

% Initialize BATCH
clear BATCH
BATCH.filename = project_path;

% Verify fMRIprep directory
if ~isfolder(FMRIPREP_DIR)
    error('fMRIprep directory not found: %s', FMRIPREP_DIR);
end

fprintf('Searching for fMRIprep data in: %s\n\n', FMRIPREP_DIR);

% Find all subject directories
subject_dirs = dir(fullfile(FMRIPREP_DIR, 'sub-*'));
subject_dirs = subject_dirs([subject_dirs.isdir]);

if isempty(subject_dirs)
    error('No subject directories (sub-*) found in %s', FMRIPREP_DIR);
end

fprintf('Found %d subjects\n\n', length(subject_dirs));

% Update project to match actual number of subjects
BATCH.Setup.nsubjects = length(subject_dirs);

% Initialize arrays
functionals = {};
structurals = {};

% Loop through subjects and collect file paths
for s = 1:length(subject_dirs)
    subject_name = subject_dirs(s).name;
    fprintf('  %2d. %s', s, subject_name);
    
    subject_path = fullfile(FMRIPREP_DIR, subject_name);
    
    % ===== FUNCTIONAL DATA =====
    % Find session directories (or use root if no sessions)
    session_dirs = dir(fullfile(subject_path, 'ses-*'));
    session_dirs = session_dirs([session_dirs.isdir]);
    
    session_funcs = {};
    
    if isempty(session_dirs)
        % No sessions - look in func folder directly
        func_dir = fullfile(subject_path, 'func');
        if isfolder(func_dir)
            % Look for preprocessed BOLD files
            bold_pattern = sprintf('*space-%s_desc-preproc_bold.nii.gz', BIDS_SPACE);
            bold_files = dir(fullfile(func_dir, bold_pattern));
            
            for f = 1:length(bold_files)
                session_funcs{end+1} = fullfile(bold_files(f).folder, bold_files(f).name);
            end
        end
    else
        % Multi-session study
        for sess = 1:length(session_dirs)
            func_dir = fullfile(subject_path, session_dirs(sess).name, 'func');
            if isfolder(func_dir)
                bold_pattern = sprintf('*space-%s_desc-preproc_bold.nii.gz', BIDS_SPACE);
                bold_files = dir(fullfile(func_dir, bold_pattern));
                
                for f = 1:length(bold_files)
                    session_funcs{end+1} = fullfile(bold_files(f).folder, bold_files(f).name);
                end
            end
        end
    end
    
    if ~isempty(session_funcs)
        functionals{s} = session_funcs;
        fprintf(' - %d func(s)', length(session_funcs));
    else
        fprintf(' - NO FUNCTIONALS FOUND');
        functionals{s} = {};
    end
    
    % ===== STRUCTURAL DATA =====
    anat_dir = fullfile(subject_path, 'anat');
    struct_file = '';
    
    if isfolder(anat_dir)
        % Look for normalized T1w
        anat_pattern = sprintf('*space-%s*T1w.nii.gz', BIDS_SPACE);
        anat_files = dir(fullfile(anat_dir, anat_pattern));
        
        if ~isempty(anat_files)
            struct_file = fullfile(anat_files(1).folder, anat_files(1).name);
            fprintf(' - struct(MNI)');
        else
            % Fallback to brain-extracted T1w
            anat_files = dir(fullfile(anat_dir, '*_brain_*.nii.gz'));
            if ~isempty(anat_files)
                struct_file = fullfile(anat_files(1).folder, anat_files(1).name);
                fprintf(' - struct(native)');
            end
        end
    end
    
    structurals{s} = struct_file;
    fprintf('\n');
end

fprintf('\n');

% Assign to BATCH
BATCH.Setup.structurals = structurals;
BATCH.Setup.functionals = functionals;
BATCH.Setup.localcopy = USE_LOCAL_COPY;

% NOW run setup with imported data and validation
fprintf('Importing data and validating CONN project...\n');
BATCH.Setup.done = 1;
BATCH.Setup.overwrite = 1;
conn_batch(BATCH);

fprintf('\n============================================\n');
fprintf('Data Import Complete\n');
fprintf('============================================\n');
fprintf('Imported: %d subjects\n', length(subject_dirs));
fprintf('Project: %s\n', project_path);
fprintf('\nNext step: Run batch_conn_03_smooth.m to apply smoothing\n\n');
