%% CONN Batch Script: Spatial Smoothing (Step 3 of 4)
%
% This script applies spatial smoothing to functional data.
% Supports volume-based and surface-based smoothing.
%
% REQUIREMENTS:
% - Existing CONN project with imported data
%   (from batch_conn_01 + batch_conn_02)
%
% USAGE:
%   From MATLAB: batch_conn_03_smooth
%   From command-line: conn batch batch_conn_03_smooth.m
%
% NEXT STEP:
%   Run batch_conn_04_denoise.m to apply denoising
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% USER CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Project
PROJECT_DIR     = '/path/to/project/directory';
PROJECT_FILE    = 'conn_project.mat';

% Smoothing: Volume-based (standard)
VOLUME_SMOOTHING_ENABLED = true;
VOLUME_SMOOTHING_FWHM    = 8;     % Full Width Half Maximum in mm
                                  % Common values: 4, 6, 8, 10 mm
                                  % Set to 0 to disable

% Smoothing: Surface-based (if available/needed)
SURFACE_SMOOTHING_ENABLED = false;
SURFACE_SMOOTHING_STEPS   = 5;    % Number of diffusion steps on surface

% Method
SMOOTHING_METHOD = 'volume';  % 'volume' or 'surface'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SMOOTHING CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n============================================\n');
fprintf('CONN Spatial Smoothing (Step 3/4)\n');
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

% Configure preprocessing with smoothing step
if VOLUME_SMOOTHING_ENABLED && VOLUME_SMOOTHING_FWHM > 0
    fprintf('Smoothing configuration:\n');
    fprintf('  Type: Volume-based\n');
    fprintf('  FWHM: %d mm\n\n', VOLUME_SMOOTHING_FWHM);
    
    BATCH.Setup.preprocessing.fwhm = VOLUME_SMOOTHING_FWHM;
    
elseif SURFACE_SMOOTHING_ENABLED
    fprintf('Smoothing configuration:\n');
    fprintf('  Type: Surface-based\n');
    fprintf('  Diffusion steps: %d\n\n', SURFACE_SMOOTHING_STEPS);
    
    BATCH.Setup.preprocessing.diffusionsteps = SURFACE_SMOOTHING_STEPS;
    
else
    fprintf('No smoothing enabled.\n\n');
    fprintf('To enable smoothing, set:\n');
    fprintf('  VOLUME_SMOOTHING_ENABLED = true and VOLUME_SMOOTHING_FWHM > 0\n');
    fprintf('  OR\n');
    fprintf('  SURFACE_SMOOTHING_ENABLED = true\n\n');
    
    fprintf('Exiting without changes.\n\n');
    return;
end

% Run preprocessing
fprintf('Applying smoothing...\n');
BATCH.Setup.done = 1;
BATCH.Setup.overwrite = 1;

try
    conn_batch(BATCH);
catch ME
    fprintf('Error during smoothing:\n%s\n', ME.message);
    rethrow(ME);
end

fprintf('\n============================================\n');
fprintf('Smoothing Complete\n');
fprintf('============================================\n');
fprintf('Smoothed data will be available in:\n');
fprintf('  <project>/results/preprocessing/\n\n');
fprintf('Next step: Run batch_conn_04_denoise.m to apply denoising\n\n');
