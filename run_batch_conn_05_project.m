%% Project-specific first-level analysis (generated)
% PROJECT_DIR set to the CONN project
PROJECT_DIR = '/data/local/069_BW01/conn';
PROJECT_FILE = 'conn_project.mat';

% Analysis options
RUN_ROI_TO_ROI = true;          % Compute ROI-to-ROI connectivity
RUN_SEED_TO_VOXEL = true;       % Compute seed-to-voxel connectivity (slower)
RUN_LOCAL_CORRELATION = false;   % Compute local correlation maps (local functional connectivity)

% Connectivity measure
CONNECTIVITY_MEASURE = 'correlation';  % 'correlation', 'partial correlation', 'regression'

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

% Run ROI-to-ROI and Seed-to-Voxel analyses sequentially to avoid struct-array assignment issues
if RUN_ROI_TO_ROI
    BATCH_ROI = [];
    BATCH_ROI.filename = project_path;
    BATCH_ROI.Analysis.analysis_number = 1;  % ROI-to-ROI analysis
    BATCH_ROI.Analysis.measure = 1;          % Bivariate correlation
    if strcmp(CONNECTIVITY_MEASURE, 'partial correlation')
        BATCH_ROI.Analysis.measure = 2;
    elseif strcmp(CONNECTIVITY_MEASURE, 'regression')
        BATCH_ROI.Analysis.measure = 3;
    end
    BATCH_ROI.Analysis.done = 1;
    BATCH_ROI.Analysis.overwrite = 1;
    fprintf('Running ROI-to-ROI analysis...\n');
    try
        conn_batch(BATCH_ROI);
        fprintf('ROI-to-ROI analysis finished.\n');
    catch ME
        fprintf('ROI-to-ROI analysis failed: %s\n', ME.message);
        rethrow(ME);
    end
end

if RUN_SEED_TO_VOXEL
    BATCH_SBC = [];
    BATCH_SBC.filename = project_path;
    BATCH_SBC.Analysis.analysis_number = 2;  % Seed-to-voxel
    BATCH_SBC.Analysis.measure = 1;          % correlation
    BATCH_SBC.Analysis.done = 1;
    BATCH_SBC.Analysis.overwrite = 1;
    fprintf('Running Seed-to-Voxel analysis (SBC)...\n');
    try
        conn_batch(BATCH_SBC);
        fprintf('Seed-to-Voxel analysis finished.\n');
    catch ME
        fprintf('Seed-to-Voxel analysis failed: %s\n', ME.message);
        rethrow(ME);
    end
end

if RUN_LOCAL_CORRELATION
    fprintf('Local-correlation requested, but requires custom implementation in CONN. Skipping.\n');
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

fprintf('============================================\n');
fprintf('First-Level Analysis Complete!\n');
fprintf('============================================\n\n');

fprintf('Output locations:\n');
fprintf('  Results:         %s/results/firstlevel/\n', PROJECT_DIR);
fprintf('  ROI timeseries:  %s/conn_project/data/ROI_Subject*.mat\n', PROJECT_DIR);
fprintf('  Project file:    %s\n\n', project_path);
