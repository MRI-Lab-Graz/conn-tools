%% CONN Batch Script: Import fMRIprep Data (Step 2 of 4)
%
% This script imports PREPROCESSED fMRIprep data into an existing CONN project.
% Uses CONN's native fMRIprep import (no additional SPM preprocessing).
% Supports both single-session and multi-session studies.
%
% REQUIREMENTS:
% - Existing CONN project (created with batch_conn_01_project_setup.m)
% - fMRIprep preprocessed data in MNI space (space-MNI152NLin2009cAsym)
%
% USAGE:
%   From MATLAB: batch_conn_02_import_fmriprep
%   From command-line: conn batch batch_conn_02_import_fmriprep.m
%
% WORKFLOW:
% 1. Load existing CONN project
% 2. Import fMRIprep data directly (NO SPM preprocessing)
% 3. Setup is validated automatically
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
BIDS_DIR        = '/path/to/bids/dataset';      % BIDS dataset root (for reference)

% fMRIprep data
FMRIPREP_DIR    = '/path/to/fmriprep/dataset'; % Root fMRIprep derivatives/fmriprep directory
BIDS_SPACE      = 'MNI152NLin2009cAsym';       % Standard space (must match fMRIprep output)
USE_LOCAL_COPY  = 0;                           % 1: Copy files locally; 0: Link to original files

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% IMPORT FMRIPREP DATA USING CONN'S BUILT-IN BIDS IMPORT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n============================================\n');
fprintf('CONN Data Import: fMRIprep (Step 2/4)\n');
fprintf('============================================\n\n');

% Load existing project
project_path = fullfile(PROJECT_DIR, PROJECT_FILE);
if ~isfile(project_path)
    error('Project file not found: %s\nRun batch_conn_01_project_setup.m first.', project_path);
end

global CONN_x;

fprintf('Loading project: %s\n', project_path);

% Verify fMRIprep directory
if ~isfolder(FMRIPREP_DIR)
    error('fMRIprep directory not found: %s', FMRIPREP_DIR);
end

fprintf('Importing from fMRIprep: %s\n', FMRIPREP_DIR);
fprintf('Space: %s\n\n', BIDS_SPACE);

% Initialize BATCH
clear BATCH
BATCH.filename = project_path;

fprintf('Discovering preprocessed BOLD files...\n');

% Find all subject directories
subject_dirs = dir(fullfile(FMRIPREP_DIR, 'sub-*'));
subject_dirs = subject_dirs([subject_dirs.isdir]);

if isempty(subject_dirs)
    error('No subject directories found in %s', FMRIPREP_DIR);
end

fprintf('Found %d subjects\n\n', length(subject_dirs));

% Collect all files organized by subject/session
functionals_by_subject = {};
structurals_by_subject = cell(length(subject_dirs), 1);
session_labels = {};
subject_session_labels = cell(length(subject_dirs), 1);
subject_session_files = cell(length(subject_dirs), 1);
default_session_label = 'session1';

for s = 1:length(subject_dirs)
    subject_name = subject_dirs(s).name;
    subject_path = fullfile(FMRIPREP_DIR, subject_name);
    
    % Determine sessions (if missing assume single session)
    session_dirs = dir(fullfile(subject_path, 'ses-*'));
    session_dirs = session_dirs([session_dirs.isdir]);
    
    local_sessions = {};
    local_files = {};
    
    if isempty(session_dirs)
        % Single session (BIDS dataset without ses- directories)
        func_dir = fullfile(subject_path, 'func');
        bold_pattern = sprintf('*space-%s*desc-preproc_bold.nii.gz', BIDS_SPACE);
        bold_files = {};
        if isfolder(func_dir)
            bold_listing = dir(fullfile(func_dir, bold_pattern));
            for f = 1:length(bold_listing)
                bold_files{end+1} = fullfile(bold_listing(f).folder, bold_listing(f).name);
            end
        end
        if ~isempty(bold_files)
            local_sessions{end+1} = default_session_label;
            local_files{end+1} = bold_files;
        end
    else
        % Multi-session - collect from each session folder
        bold_pattern = sprintf('*space-%s*desc-preproc_bold.nii.gz', BIDS_SPACE);
        for sess = 1:length(session_dirs)
            func_dir = fullfile(subject_path, session_dirs(sess).name, 'func');
            bold_files = {};
            if isfolder(func_dir)
                bold_listing = dir(fullfile(func_dir, bold_pattern));
                for f = 1:length(bold_listing)
                    bold_files{end+1} = fullfile(bold_listing(f).folder, bold_listing(f).name);
                end
            end
            if ~isempty(bold_files)
                local_sessions{end+1} = session_dirs(sess).name;
                local_files{end+1} = bold_files;
            end
        end
    end

    if isempty(local_sessions)
        fprintf('Warning: No BOLD files found for %s in space %s\n', subject_name, BIDS_SPACE);
        local_sessions{end+1} = default_session_label;
        local_files{end+1} = {};
    end
    
    subject_session_labels{s} = local_sessions;
    subject_session_files{s} = local_files;
    session_labels = [session_labels, local_sessions];

    % Find structural (use same for all sessions if multi-session)
    anat_dir = fullfile(subject_path, 'anat');
    struct_file = '';
    if isfolder(anat_dir)
        % MNI-space T1w preferred
        anat_pattern = sprintf('*space-%s*T1w.nii.gz', BIDS_SPACE);
        anat_files = dir(fullfile(anat_dir, anat_pattern));
        
        if ~isempty(anat_files)
            struct_file = fullfile(anat_files(1).folder, anat_files(1).name);
        else
            % Fallback to native space
            anat_files = dir(fullfile(anat_dir, '*_T1w.nii.gz'));
            if ~isempty(anat_files)
                struct_file = fullfile(anat_files(1).folder, anat_files(1).name);
            end
        end
    end
    
    structurals_by_subject{s} = struct_file;
end

session_labels = unique(session_labels, 'stable');
if isempty(session_labels)
    session_labels = {default_session_label};
end

nsessions_total = numel(session_labels);
fprintf('Detected %d unique session label(s)\n\n', nsessions_total);

% Map session labels to columns
session_index_map = containers.Map(session_labels, 1:nsessions_total);

% Initialize storage grid and fill with discovered files
functionals_by_subject = repmat({{}}, length(subject_dirs), nsessions_total);
for s = 1:length(subject_dirs)
    local_sessions = subject_session_labels{s};
    local_files = subject_session_files{s};
    for ss = 1:length(local_sessions)
        label = local_sessions{ss};
        idx = session_index_map(label);
        functionals_by_subject{s, idx} = local_files{ss};
    end
end

fprintf('Collected files for all subjects and sessions\n\n');

% Set up BATCH for import (no ROI/preprocessing)
fprintf('Assigning imports to CONN project...\n');
BATCH.Setup.functionals = functionals_by_subject;
BATCH.Setup.structurals = structurals_by_subject;
BATCH.Setup.localcopy = USE_LOCAL_COPY;

% Define a single resting-state condition across all discovered sessions
nsubjects = size(functionals_by_subject, 1);
nsessions_total = size(functionals_by_subject, 2);
BATCH.Setup.conditions.names = {'rest'};
BATCH.Setup.conditions.onsets = {repmat({{}}, nsubjects, 1)};
BATCH.Setup.conditions.durations = {repmat({{}}, nsubjects, 1)};
for nsub = 1:nsubjects
    for nses = 1:nsessions_total
        BATCH.Setup.conditions.onsets{1}{nsub}{nses} = 0;
        BATCH.Setup.conditions.durations{1}{nsub}{nses} = inf;
    end
end
BATCH.Setup.conditions.missingdata = 1;

% Run import only (no preprocessing/segmentation/ROI)
fprintf('Importing into CONN project (import only, no preprocessing)...\n');
BATCH.Setup.done = 0;
BATCH.Setup.overwrite = 1;

try
    conn_batch(BATCH);
catch ME
    fprintf('Error during import: %s\n', ME.message);
    if isfield(ME, 'identifier') && ~isempty(ME.identifier)
        fprintf('  Identifier: %s\n', ME.identifier);
    end
    fprintf('  Stack:\n');
    for s = 1:length(ME.stack)
        fprintf('    %s (line %d)\n', ME.stack(s).file, ME.stack(s).line);
    end
    rethrow(ME);
end

fprintf('\nSetting up resting-state condition for each session...\n');
% Use local nsubjects instead of CONN_x.Setup.nsubjects since setup wasn't run
try
    conn_importcondition(struct('conditions', {{'rest'}}, 'onsets', 0, 'durations', inf, 'breakconditionsbysession', false, 'deleteall', false), ...
        'subjects', 1:nsubjects, 'sessions', 0);
catch ME
    fprintf('Warning: conn_importcondition failed: %s\n', ME.message);
end

fprintf('\nImporting ROIs (standard CONN atlas)...\n');
% Import CONN's standard atlas definition (timeseries extraction happens during analysis)
try
    BATCH_ROI = [];
    BATCH_ROI.filename = project_path;
    % Import the Networks atlas (common default in CONN)
    BATCH_ROI.Setup.rois.files = {fullfile(fileparts(which('conn')), 'rois', 'networks.nii')};
    BATCH_ROI.Setup.rois.names = {'Networks'};
    
    % Check if atlas file exists, use fallback if needed
    atlas_file = BATCH_ROI.Setup.rois.files{1};
    if ~isfile(atlas_file)
        fprintf('Warning: Standard atlas not found at %s\n', atlas_file);
        fprintf('Attempting to use default CONN atlas location...\n');
        % Try alternative paths
        conn_root = fileparts(fileparts(which('conn')));
        alt_paths = {
            fullfile(conn_root, 'conn', 'rois', 'networks.nii')
            fullfile(conn_root, 'rois', 'networks.nii')
            fullfile(conn_root, 'atlases', 'networks.nii')
        };
        found = false;
        for p = 1:length(alt_paths)
            if isfile(alt_paths{p})
                BATCH_ROI.Setup.rois.files = {alt_paths{p}};
                fprintf('Found atlas at: %s\n', alt_paths{p});
                found = true;
                break;
            end
        end
        if ~found
            fprintf('Warning: Could not locate CONN atlas files. Skipping ROI import.\n');
            fprintf('You can import ROIs later from the CONN GUI.\n');
        end
    end
    
    if isfile(BATCH_ROI.Setup.rois.files{1})
        % Import ROI definitions only (don't extract timeseries yet)
        % Timeseries extraction will happen automatically during first-level analysis
        BATCH_ROI.Setup.done = 0;
        BATCH_ROI.Setup.overwrite = 1;
        
        conn_batch(BATCH_ROI);
        fprintf('ROI atlas imported successfully.\n');
        fprintf('Note: ROI timeseries will be extracted automatically during first-level analysis.\n');
    end
    
catch ME
    fprintf('Warning: ROI import failed: %s\n', ME.message);
    fprintf('You can import ROIs later from the CONN GUI.\n');
end


fprintf('\n============================================\n');
fprintf('Data Import Complete\n');
fprintf('============================================\n');
fprintf('Imported: %d subjects\n', length(subject_dirs));
fprintf('Space: %s\n', BIDS_SPACE);
fprintf('Project: %s\n', project_path);
fprintf('\nNext step: Run batch_conn_03_smooth.m to apply spatial smoothing\n\n');
