%% CONN Batch Script: First-Level Analysis (Optional Step 5)
%
% This script runs first-level connectivity analyses.
% This step extracts ROI timeseries and computes connectivity metrics.
%
% REQUIREMENTS:
% - Existing CONN project with denoised data
%   (from batch_conn_01 through batch_conn_04)
%
% USAGE:
%   From MATLAB: batch_conn_05_analysis
%   From command-line: conn batch batch_conn_05_analysis.m
%
% ANALYSES PERFORMED:
%   - ROI timeseries extraction
%   - ROI-to-ROI connectivity (bivariate correlation)
%   - Seed-to-Voxel connectivity (optional)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% USER CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Project
PROJECT_DIR     = '/path/to/project/directory';
PROJECT_FILE    = 'conn_project.mat';

% Analysis options
RUN_ROI_TO_ROI = true;          % Compute ROI-to-ROI connectivity
RUN_SEED_TO_VOXEL = true;       % Compute seed-to-voxel connectivity (slower)
RUN_LOCAL_CORRELATION = false;   % Compute local correlation maps (local functional connectivity)

% Connectivity measure
CONNECTIVITY_MEASURE = 'correlation';  % 'correlation', 'partial correlation', 'regression'

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ANALYSIS EXECUTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf('\n============================================\n');
fprintf('CONN First-Level Analysis (Step 5)\n');
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

% ===== FIRST-LEVEL ANALYSIS CONFIGURATION =====

fprintf('Analysis configuration:\n');
if RUN_ROI_TO_ROI
    fprintf('  ROI-to-ROI:     enabled\n');
else
    fprintf('  ROI-to-ROI:     disabled\n');
end
if RUN_SEED_TO_VOXEL
    fprintf('  Seed-to-Voxel:  enabled\n');
else
    fprintf('  Seed-to-Voxel:  disabled\n');
end
if RUN_LOCAL_CORRELATION
    fprintf('  Local-corr:     enabled\n');
else
    fprintf('  Local-corr:     disabled\n');
end
fprintf('  Measure:        %s\n\n', CONNECTIVITY_MEASURE);

% Configure analyses
analysis_index = 0;
if RUN_ROI_TO_ROI
    analysis_index = analysis_index + 1;
    BATCH.Analysis(analysis_index).analysis_number = 1;  % ROI-to-ROI analysis
    BATCH.Analysis(analysis_index).measure = 1;           % Bivariate correlation
    if strcmp(CONNECTIVITY_MEASURE, 'partial correlation')
        BATCH.Analysis(analysis_index).measure = 2;
    elseif strcmp(CONNECTIVITY_MEASURE, 'regression')
        BATCH.Analysis(analysis_index).measure = 3;
    end
end

% Seed-to-voxel (Seed-based connectivity, SBC)
if RUN_SEED_TO_VOXEL
    analysis_index = analysis_index + 1;
    % Use a separate analysis slot for seed-to-voxel maps
    BATCH.Analysis(analysis_index).analysis_number = 2;  % seed-to-voxel
    BATCH.Analysis(analysis_index).measure = 1;          % correlation (default)
    % For seed-to-voxel, CONN will use ROIs defined in the project as seeds
end

% Local correlation (local functional connectivity)
if RUN_LOCAL_CORRELATION
    analysis_index = analysis_index + 1;
    BATCH.Analysis(analysis_index).analysis_number = 3;  % local correlation placeholder
    BATCH.Analysis(analysis_index).measure = 4;          % placeholder measure id for localcorr
    % Note: CONN's exact field names for local-correlation may differ; adjust if necessary
end

% ===== RUN ANALYSIS =====

fprintf('Running first-level analysis...\n');
fprintf('This will:\n');
fprintf('  1. Extract ROI timeseries from denoised data\n');
fprintf('  2. Compute connectivity matrices\n');
fprintf('  3. Save results for second-level analysis\n\n');

BATCH.Analysis.done = 1;
BATCH.Analysis.overwrite = 1;

try
    conn_batch(BATCH);
    fprintf('First-level analysis completed successfully.\n\n');
catch ME
    fprintf('Error during analysis:\n%s\n', ME.message);
    rethrow(ME);
end

% ===== COMPLETION MESSAGE =====

fprintf('============================================\n');
fprintf('First-Level Analysis Complete!\n');
fprintf('============================================\n\n');

fprintf('Output locations:\n');
fprintf('  Results:         %s/results/firstlevel/\n', PROJECT_DIR);
fprintf('  ROI timeseries:  %s/conn_project/data/ROI_Subject*.mat\n', PROJECT_DIR);
fprintf('  Project file:    %s\n\n', project_path);

fprintf('Next steps:\n');
fprintf('  1. Review connectivity matrices\n');
fprintf('  2. Define second-level contrasts\n');
fprintf('  3. Run second-level group analyses\n\n');

fprintf('To view results:\n');
fprintf('  - Open CONN GUI\n');
fprintf('  - Load project: %s\n', project_path);
fprintf('  - Navigate to Results > First-level\n\n');

% ===== HELPER FUNCTION =====

function result = iif(condition, true_val, false_val)
    % Inline if function
    if condition
        result = true_val;
    else
        result = false_val;
    end
end
