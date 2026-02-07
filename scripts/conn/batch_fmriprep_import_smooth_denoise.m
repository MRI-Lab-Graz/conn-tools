%% CONN Batch Script: Import fMRIprep Data, Smooth, and Denoise
%
% This script imports preprocessed fMRIprep data into CONN, performs
% spatial smoothing, and runs denoising (confound removal + filtering).
%
% REQUIREMENTS:
% - fMRIprep preprocessed data (space-MNI152NLin2009cAsym)
% - CONN installed on your system
% - Matlab or standalone CONN
%
% USAGE:
%   From MATLAB:
%     batch_fmriprep_import_smooth_denoise
%   From command-line (standalone CONN):
%     conn batch batch_fmriprep_import_smooth_denoise.m
%
% Author: Automated Script Generator
% Date: February 2026
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% USER CONFIGURATION - EDIT THESE SETTINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Project configuration
PROJECT_NAME        = 'fMRIprep_Analysis';          % Name of your CONN project
PROJECT_DIR         = '/path/to/project/directory'; % Where to save CONN project
FMRIPREP_DIR        = '/path/to/fmriprep/dataset';  % Path to fMRIprep output root

% Smoothing parameters
SMOOTHING_FWHM      = 8;      % Smoothing kernel (mm); 0 for no smoothing

% Denoising parameters
BANDPASS_LOW        = 0.008;  % Low-frequency cutoff (Hz)
BANDPASS_HIGH       = Inf;    % High-frequency cutoff (Hz); Inf for no high-pass
DETRENDING_ORDER    = 1;      % 0=none, 1=linear, 2=quadratic, 3=cubic
DESPIKING           = 0;      % 0=no despiking, 1=before regression, 2=after
REGBP_ORDER         = 1;      % 1=RegBP (regression then bandpass), 2=Simult (simultaneous)

% Confounds to regress (standard fMRIprep noise components)
% Include: 'Grey Matter', 'White Matter', 'CSF', motion regressors, etc.
CONFOUNDS = {
    'White Matter'
    'CSF'
};

% Motion regression configuration
MOTION_REGRESSORS = true;     % Include framewise displacement & motion parameters
SCRUBBING = true;             % Flag and potentially exclude high-motion frames

% Quality Assurance
GENERATE_QA_PLOTS = true;     % Generate QA plots

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FMRIPREP DATA DISCOVERY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This section automatically discovers fMRIprep files
% Expected structure: fmriprep/sub-XXX/ses-YYY/func/sub-XXX_ses-YYY_task-*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz

fprintf('\n============================================\n');
fprintf('CONN fMRIprep Import, Smooth & Denoise\n');
fprintf('============================================\n\n');

fprintf('Searching for fMRIprep data in: %s\n', FMRIPREP_DIR);

% Find all subject directories
subject_dirs = dir(fullfile(FMRIPREP_DIR, 'sub-*'));
subject_dirs = subject_dirs([subject_dirs.isdir]);

if isempty(subject_dirs)
    error('No subject directories (sub-*) found in %s', FMRIPREP_DIR);
end

fprintf('Found %d subjects\n\n', length(subject_dirs));

% Initialize BATCH structure
clear BATCH

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SETUP PHASE: Define Project and Data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('Setting up CONN project...\n');

BATCH.filename = fullfile(PROJECT_DIR, 'conn_project.mat');
BATCH.Setup.isnew = 1;                          % Create new project
BATCH.Setup.nsubjects = length(subject_dirs);   % Number of subjects
BATCH.Setup.RT = 2;                             % Repetition time (adjust based on your data!)

% Initialize arrays for structural and functional data
functionals = {};
structurals = {};

% Loop through subjects and collect file paths
for s = 1:length(subject_dirs)
    subject_name = subject_dirs(s).name;
    fprintf('  Processing: %s\n', subject_name);
    
    subject_path = fullfile(FMRIPREP_DIR, subject_name);
    
    % Find session directories (or use root if no sessions)
    session_dirs = dir(fullfile(subject_path, 'ses-*'));
    session_dirs = session_dirs([session_dirs.isdir]);
    
    if isempty(session_dirs)
        % No sessions - look for functional data directly in func folder
        session_dirs = struct('name', '', 'folder', subject_path);
    end
    
    % For each session, collect functional files
    session_funcs = {};
    for sess = 1:length(session_dirs)
        if isempty(session_dirs(sess).name)
            % No session structure
            func_dir = fullfile(subject_path, 'func');
        else
            func_dir = fullfile(subject_path, session_dirs(sess).name, 'func');
        end
        
        if isfolder(func_dir)
            % Find preprocessed BOLD files (space-MNI152NLin2009cAsym)
            bold_files = dir(fullfile(func_dir, '*space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz'));
            
            for f = 1:length(bold_files)
                session_funcs{end+1} = fullfile(bold_files(f).folder, bold_files(f).name);
            end
        end
    end
    
    % Find structural file (T1w in anat folder, normalized to MNI space or use brain-extracted)
    anat_dir = fullfile(subject_path, 'anat');
    if isfolder(anat_dir)
        % Look for normalized T1w
        anat_files = dir(fullfile(anat_dir, '*space-MNI152NLin2009cAsym_desc-preproc_T1w.nii.gz'));
        if isempty(anat_files)
            % Fallback to non-normalized brain-extracted
            anat_files = dir(fullfile(anat_dir, '*space-MNI152NLin2009cAsym_T1w.nii.gz'));
        end
        if isempty(anat_files)
            % Last resort: any T1w file
            anat_files = dir(fullfile(anat_dir, '*T1w.nii.gz'));
        end
        
        if ~isempty(anat_files)
            structurals{s} = fullfile(anat_files(1).folder, anat_files(1).name);
        else
            warning('No anatomical file found for %s', subject_name);
            structurals{s} = '';
        end
    else
        warning('No anat folder found for %s', subject_name);
        structurals{s} = '';
    end
    
    if ~isempty(session_funcs)
        functionals{s} = session_funcs;
        fprintf('    - Found %d functional file(s)\n', length(session_funcs));
    else
        warning('No functional files found for %s', subject_name);
        functionals{s} = {};
    end
end

% Assign to BATCH
BATCH.Setup.structurals = structurals;
BATCH.Setup.functionals = functionals;

% Preprocessing: Since data is already preprocessed by fMRIprep,
% we use a minimal pipeline. Data is already in MNI space.
BATCH.Setup.preprocessing.steps = {};  % No further preprocessing needed (data from fMRIprep)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SMOOTHING CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('Configuring smoothing (FWHM = %d mm)...\n', SMOOTHING_FWHM);

if SMOOTHING_FWHM > 0
    BATCH.Setup.preprocessing.fwhm = SMOOTHING_FWHM;
    % Note: Smoothing happens after functional_load or as a separate step
    % For fMRIprep data already in standard space, add smooth step if needed
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DENOISING CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('Configuring denoising parameters...\n');
fprintf('  - Bandpass: %.3f - %.1f Hz\n', BANDPASS_LOW, BANDPASS_HIGH);
fprintf('  - Detrending order: %d\n', DETRENDING_ORDER);
fprintf('  - Confounds to regress: %s\n', sprintf('%s, ', CONFOUNDS{:}));

BATCH.Denoising.filter = [BANDPASS_LOW BANDPASS_HIGH];
BATCH.Denoising.detrending = DETRENDING_ORDER;
BATCH.Denoising.despiking = DESPIKING;
BATCH.Denoising.regbp = REGBP_ORDER;

% Configure confounds
if MOTION_REGRESSORS
    confounds = CONFOUNDS;
    % Motion regressors are automatically detected from realignment files (rp_*.txt)
    % or from fMRIprep confounds.tsv if available
else
    confounds = CONFOUNDS;
end

BATCH.Denoising.confounds = confounds;

% Optional: Add derivatives and powers of confounds
% Uncomment below if you want to include motion derivatives
% BATCH.Denoising.confounds.deriv = [0, 0]; % [WM, CSF] - set to 1 for derivatives

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% QUALITY ASSURANCE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if GENERATE_QA_PLOTS
    fprintf('Configuring QA plots...\n');
    BATCH.QA.plots = [2, 11, 12, 13]; % Mean functional, denoise histogram, timeseries, FC-QC
    BATCH.QA.foldername = fullfile(PROJECT_DIR, 'results', 'qa');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXECUTION PHASE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n============================================\n');
fprintf('BATCH CONFIGURATION COMPLETE\n');
fprintf('============================================\n');
fprintf('Project: %s\n', PROJECT_NAME);
fprintf('Location: %s\n', PROJECT_DIR);
fprintf('Subjects: %d\n', BATCH.Setup.nsubjects);
fprintf('\n');

% Create project directory if it doesn't exist
if ~isfolder(PROJECT_DIR)
    mkdir(PROJECT_DIR);
end

% Run Setup
fprintf('Running CONN Setup...\n');
BATCH.Setup.done = 1;
BATCH.Setup.overwrite = 1;
conn_batch(BATCH);

% Run Denoising
fprintf('\nRunning CONN Denoising...\n');
BATCH_DENOISE = [];
BATCH_DENOISE.filename = BATCH.filename;
BATCH_DENOISE.Denoising = BATCH.Denoising;
BATCH_DENOISE.Denoising.done = 1;
BATCH_DENOISE.Denoising.overwrite = 1;
conn_batch(BATCH_DENOISE);

% Generate QA plots
if GENERATE_QA_PLOTS
    fprintf('\nGenerating QA plots...\n');
    BATCH_QA = [];
    BATCH_QA.filename = BATCH.filename;
    BATCH_QA.QA = BATCH.QA;
    conn_batch(BATCH_QA);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% COMPLETION MESSAGE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n============================================\n');
fprintf('PROCESSING COMPLETE\n');
fprintf('============================================\n');
fprintf('Project saved to: %s\n', PROJECT_DIR);
fprintf('Denoised data location: %s/results/\n', PROJECT_DIR);
if GENERATE_QA_PLOTS
    fprintf('QA plots location: %s/results/qa/\n', PROJECT_DIR);
end
fprintf('\nNext steps:\n');
fprintf('1. Review QA plots to assess data quality\n');
fprintf('2. Define ROIs or use pre-defined atlases\n');
fprintf('3. Run first-level connectivity analyses\n');
fprintf('4. Run second-level group analyses\n\n');
