%% CONN Batch Script: Project Setup (Step 1 of 4)
%
% This script creates and configures a new CONN project with basic settings.
% It initializes the project structure but does NOT import any data.
%
% USAGE:
%   From MATLAB: batch_conn_01_project_setup
%   From command-line: conn batch batch_conn_01_project_setup.m
%
% NEXT STEP:
%   Run batch_conn_02_import_fmriprep.m to import data
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% USER CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Project information
% NOTE: These values are automatically populated from BIDS metadata by the pipeline.
% They are set to defaults here, but will be overridden by the bash wrapper script.
PROJECT_NAME        = 'My_fMRI_Project';            % Descriptive project name
PROJECT_DIR         = '/path/to/project/directory'; % Where to save CONN project
BIDS_DIR            = '/path/to/bids/dataset';      % BIDS dataset root
NSUBJECTS           = 30;                           % Number of subjects (from BIDS)
REPETITION_TIME     = 2.0;                          % TR in seconds (from BIDS metadata)

% Acquisition settings
ACQUISITION_CONTINUOUS = 1;  % 1: Continuous acquisition; 0: Event-related
ANALYSISUNITS           = 1; % 1: PSC (percent signal change); 2: Raw units
VOXEL_RESOLUTION        = 1; % 1: 2mm MNI template (default); 2: Same as structurals; 3: Same as functionals; 4: Surface-based

% Multi-session settings
DETECT_SESSIONS         = 1; % 1: Auto-detect sessions; 0: Single-session
SESSIONS_TO_ANALYZE     = {};% Specific sessions to include (empty = all found)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SESSION DETECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Automatically detect multi-session structure
sessions_found = {};
if DETECT_SESSIONS && isfolder(BIDS_DIR)
    first_subject = dir(fullfile(BIDS_DIR, 'sub-*'));
    first_subject = first_subject([first_subject.isdir]);
    if ~isempty(first_subject)
        sub_path = fullfile(BIDS_DIR, first_subject(1).name);
        ses_dirs = dir(fullfile(sub_path, 'ses-*'));
        ses_dirs = ses_dirs([ses_dirs.isdir]);
        if ~isempty(ses_dirs)
            for s = 1:length(ses_dirs)
                sessions_found{s} = ses_dirs(s).name;
            end
            fprintf('Multi-session dataset detected!\n');
            fprintf('  Sessions found: %s\n', strjoin(sessions_found, ', '));
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXECUTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n============================================\n');
fprintf('CONN Project Setup (Step 1/4)\n');
fprintf('============================================\n\n');

% Create project directory
if ~isfolder(PROJECT_DIR)
    fprintf('Creating project directory: %s\n', PROJECT_DIR);
    mkdir(PROJECT_DIR);
end

% Validate BIDS directory
if ~isfolder(BIDS_DIR)
    fprintf('Warning: BIDS directory not accessible: %s\n', BIDS_DIR);
end

% Initialize BATCH structure
clear BATCH

% Configure project
BATCH.filename = fullfile(PROJECT_DIR, 'conn_project.mat');
BATCH.Setup.isnew = 1;                          % New project
BATCH.Setup.nsubjects = NSUBJECTS;              % Number of subjects
BATCH.Setup.RT = REPETITION_TIME;               % Repetition time
BATCH.Setup.nsessions = length(sessions_found); % Number of sessions

% Acquisition settings
BATCH.Setup.acquisitiontype = ACQUISITION_CONTINUOUS;
BATCH.Setup.analysisunits = ANALYSISUNITS;
BATCH.Setup.voxelresolution = VOXEL_RESOLUTION;

% Store BIDS metadata for reproducibility
BATCH.Setup.BIDS_dir = BIDS_DIR;                % Reference to BIDS dataset
BATCH.Setup.BIDS_sessions = sessions_found;     % Sessions detected

fprintf('Project settings:\n');
fprintf('  Name: %s\n', PROJECT_NAME);
fprintf('  Directory: %s\n', PROJECT_DIR);
fprintf('  BIDS: %s\n', BIDS_DIR);
fprintf('  Subjects: %d (extracted from BIDS dataset)\n', NSUBJECTS);
fprintf('  TR: %.3f seconds (extracted from BIDS JSON metadata)\n', REPETITION_TIME);
if ~isempty(sessions_found)
    fprintf('  Sessions: %d (detected in BIDS structure)\n', length(sessions_found));
    fprintf('    - %s\n', strjoin(sessions_found, sprintf('\n    - ')));
end
fprintf('\n');

% Run setup
fprintf('Creating CONN project skeleton...\n');
BATCH.Setup.done = 0;  % Just create structure, don't validate yet
conn_batch(BATCH);

fprintf('\n============================================\n');
fprintf('Project Setup Complete\n');
fprintf('============================================\n');
fprintf('Project file: %s\n', BATCH.filename);
fprintf('Project directory: %s/conn_project/\n', PROJECT_DIR);
fprintf('\nNext step: Run batch_conn_02_import_fmriprep.m\n\n');
