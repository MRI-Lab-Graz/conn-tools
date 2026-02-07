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
PROJECT_NAME        = 'My_fMRI_Project';            % Descriptive project name
PROJECT_DIR         = '/path/to/project/directory'; % Where to save CONN project
NSUBJECTS           = 30;                           % Number of subjects
REPETITION_TIME     = 2.0;                          % TR in seconds (adjust as needed)

% Acquisition settings
ACQUISITION_CONTINUOUS = 1;  % 1: Continuous acquisition; 0: Event-related
ANALYSISUNITS           = 1; % 1: PSC (percent signal change); 2: Raw units
VOXEL_RESOLUTION        = 1; % 1: 2mm MNI template (default); 2: Same as structurals; 3: Same as functionals; 4: Surface-based

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

% Initialize BATCH structure
clear BATCH

% Configure project
BATCH.filename = fullfile(PROJECT_DIR, 'conn_project.mat');
BATCH.Setup.isnew = 1;                          % New project
BATCH.Setup.nsubjects = NSUBJECTS;              % Number of subjects
BATCH.Setup.RT = REPETITION_TIME;               % Repetition time

% Acquisition settings
BATCH.Setup.acquisitiontype = ACQUISITION_CONTINUOUS;
BATCH.Setup.analysisunits = ANALYSISUNITS;
BATCH.Setup.voxelresolution = VOXEL_RESOLUTION;

fprintf('Project settings:\n');
fprintf('  Name: %s\n', PROJECT_NAME);
fprintf('  Directory: %s\n', PROJECT_DIR);
fprintf('  Subjects: %d (placeholder - will be updated during import)\n', NSUBJECTS);
fprintf('  TR: %.1f seconds\n', REPETITION_TIME);
fprintf('\n');

% Run setup
fprintf('Creating CONN project skeleton...\n');
BATCH.Setup.done = 0;  % Just create structure, don't validate yet
conn_batch(BATCH);

fprintf('\n============================================\n');
fprintf('Project Setup Complete\n');
fprintf('============================================\n');
fprintf('Project file: %s\n', BATCH.filename);
fprintf('\nNext step: Run batch_conn_02_import_fmriprep.m\n\n');
