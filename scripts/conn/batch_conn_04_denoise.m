%% CONN Batch Script: Denoising (Step 4 of 4)
%
% This script performs denoising: confound regression and band-pass filtering.
%
% REQUIREMENTS:
% - Existing CONN project with imported and smoothed data
%   (from batch_conn_01 + batch_conn_02 + batch_conn_03)
%
% USAGE:
%   From MATLAB: batch_conn_04_denoise
%   From command-line: conn batch batch_conn_04_denoise.m
%
% This is the final preprocessing step before analysis.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% USER CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Project
PROJECT_DIR     = '/path/to/project/directory';
PROJECT_FILE    = 'conn_project.mat';

% Band-pass filtering
BANDPASS_LOW    = 0.008;    % Low-frequency cutoff (Hz)
                            % 0.008 Hz = 125 sec period
                            % Common: 0.008-0.01 Hz
BANDPASS_HIGH   = Inf;      % High-frequency cutoff (Hz)
                            % Inf = no high-pass filtering
                            % Common: 0.1 Hz for limited band-pass

% Detrending
DETRENDING_ORDER = 1;       % 0: none, 1: linear, 2: quadratic, 3: cubic
                            % Recommended: 1 (linear)

% Despiking (temporal artifact removal)
DESPIKING_ENABLED = false;  % 0: disabled, 1: before regression, 2: after regression

% Regression and band-pass order
REGBP_ORDER = 1;            % 1: RegBP (regression then bandpass)
                            % 2: Simult (simultaneous regression & bandpass)
                            % Recommended: 1

% Confounds to regress
% Standard set: White Matter, CSF (always recommended)
CONFOUNDS_STANDARD = {'White Matter', 'CSF'};

% Advanced: Include motion regressors
CONFOUNDS_WITH_MOTION = {'White Matter', 'CSF', 'Realignment', 'Scrubbing'};

% Use standard or advanced?
USE_STANDARD_CONFOUNDS = true;

% Motion scrubbing
SCRUBBING_ENABLED = false;  % Flag high-motion frames for exclusion

% Motion regression derivatives
INCLUDE_MOTION_DERIVATIVES = false;  % Include motion derivatives (6 params -> 12)

% Quality Assurance
GENERATE_QA_PLOTS = true;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% DENOISING EXECUTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n============================================\n');
fprintf('CONN Denoising (Step 4/4)\n');
fprintf('============================================\n\n');

% Load project
project_path = fullfile(PROJECT_DIR, PROJECT_FILE);
if ~isfile(project_path)
    error('Project file not found: %s', project_path);
end

fprintf('Project: %s\n\n', project_path);

% Initialize BATCH
clear BATCH
BATCH.filename = project_path;

% ===== DENOISING CONFIGURATION =====

fprintf('Denoising configuration:\n');
fprintf('  Band-pass filter: %.3f - %.1f Hz\n', BANDPASS_LOW, BANDPASS_HIGH);
fprintf('  Detrending order: %d\n', DETRENDING_ORDER);
if DESPIKING_ENABLED
    despiking_status = 'enabled';
else
    despiking_status = 'disabled';
end
if REGBP_ORDER==1
    regbp_label = 'RegBP';
else
    regbp_label = 'Simult';
end
fprintf('  Despiking: %s\n', despiking_status);
fprintf('  Reg-BP order: %d (%s)\n', REGBP_ORDER, regbp_label);

% Select confounds
if USE_STANDARD_CONFOUNDS
    confounds = CONFOUNDS_STANDARD;
    fprintf('  Confounds: Standard (WM, CSF)\n');
else
    confounds = CONFOUNDS_WITH_MOTION;
    fprintf('  Confounds: With motion\n');
end

if INCLUDE_MOTION_DERIVATIVES
    fprintf('  Motion derivatives: Yes\n');
else
    fprintf('  Motion derivatives: No\n');
end

if SCRUBBING_ENABLED
    scrubbing_status = 'enabled';
else
    scrubbing_status = 'disabled';
end
fprintf('  Scrubbing: %s\n\n', scrubbing_status);

% Configure denoising
BATCH.Denoising.filter = [BANDPASS_LOW BANDPASS_HIGH];
BATCH.Denoising.detrending = DETRENDING_ORDER;
BATCH.Denoising.despiking = DESPIKING_ENABLED;
BATCH.Denoising.regbp = REGBP_ORDER;
BATCH.Denoising.confounds = confounds;

% Optional: Motion derivatives
if INCLUDE_MOTION_DERIVATIVES && ismember('Realignment', confounds)
    % Derivatives will be automatically included when specified in confounds
end

% ===== RUN DENOISING =====

fprintf('Running denoising...\n');
BATCH.Denoising.done = 1;
BATCH.Denoising.overwrite = 1;
% Skip full setup (data already preprocessed by fMRIprep)
BATCH.Setup.done = 0;

try
    conn_batch(BATCH);
    fprintf('Denoising completed successfully.\n\n');
catch ME
    fprintf('Error during denoising:\n%s\n', ME.message);
    rethrow(ME);
end

% ===== QUALITY ASSURANCE PLOTS =====

if GENERATE_QA_PLOTS
    roi_probe = fullfile(PROJECT_DIR, 'conn_project', 'data', 'ROI_Subject001_Session001.mat');
    if ~isfile(roi_probe)
        fprintf('Warning: ROI timeseries files missing: %s\n', roi_probe);
        fprintf('Skipping QA plots that require ROI data.\n\n');
    else
        fprintf('Generating QA plots...\n');

        BATCH_QA = [];
        BATCH_QA.filename = project_path;
        BATCH_QA.QA.plots = [2, 11, 12, 13];  % Mean func, denoise hist, timeseries, FC-QC
        BATCH_QA.QA.foldername = fullfile(PROJECT_DIR, 'results', 'qa');

        try
            conn_batch(BATCH_QA);
            fprintf('QA plots generated in: %s\n\n', BATCH_QA.QA.foldername);
        catch ME
            fprintf('Warning: QA plot generation failed: %s\n\n', ME.message);
        end
    end
end

% ===== COMPLETION MESSAGE =====

fprintf('============================================\n');
fprintf('Denoising Complete!\n');
fprintf('============================================\n\n');

fprintf('Output locations:\n');
fprintf('  Denoised data:   %s/results/denoising/\n', PROJECT_DIR);
fprintf('  QA plots:        %s/results/qa/\n', PROJECT_DIR);
fprintf('  Project file:    %s\n\n', project_path);

fprintf('Next steps:\n');
fprintf('  1. Review QA plots to verify preprocessing quality\n');
fprintf('  2. Define ROIs or load standard atlases\n');
fprintf('  3. Run first-level connectivity analyses\n');
fprintf('  4. Run second-level group-level analyses\n\n');

fprintf('Available analyses in CONN:\n');
fprintf('  - ROI-to-ROI connectivity\n');
fprintf('  - Seed-to-Voxel connectivity\n');
fprintf('  - Voxel-to-Voxel connectivity\n');
fprintf('  - Dynamic connectivity\n');
fprintf('  - Network-based statistics\n\n');


