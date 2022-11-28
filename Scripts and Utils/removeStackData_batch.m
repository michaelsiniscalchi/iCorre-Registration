function removeStackData_batch(root_dir)

%% Get list of data directories
temp = dir(root_dir); %Edit to specify data directories
data_dirs = {temp.name};
temp = ~(ismember(data_dirs,{'.','..'})) & isfolder(fullfile({root_dir},data_dirs));
data_dirs = data_dirs(temp); %remove '.', '..', subdirs, and any files from directory list
disp(['Root directory: ' root_dir]);
disp('Directories to process:');
disp(data_dirs');
clearvars temp;

for i = 1:numel(data_dirs)
    
    % Get Subdirectories and File Paths
    [~, paths] = iCorreFilePaths(root_dir, data_dirs{i}, 'raw');
    
    % Remove stacks from saved MAT files
    removeStackData(paths.mat);

end