% Minimal CONN setup to process conditions without running preprocessing/segmentation
PROJECT_DIR = '/data/local/069_BW01/conn';
PROJECT_FILE = 'conn_project.mat';
project_path = fullfile(PROJECT_DIR, PROJECT_FILE);

if ~isfile(project_path)
    error('Project file not found: %s', project_path);
end

clear BATCH
BATCH.filename = project_path;
% Disable all preprocessing steps
BATCH.Setup.preprocessing.steps = {};
% Run setup to process conditions/variables but skip actual preprocessing
BATCH.Setup.done = 1;
BATCH.Setup.overwrite = 1;

try
    conn_batch(BATCH);
    fprintf('Minimal setup completed.\n');
catch ME
    fprintf('Minimal setup failed: %s\n', ME.message);
    rethrow(ME);
end
