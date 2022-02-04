function [ dirs, paths ] = setup_stitchDirs( data_dir, chan_num )

% Define & Create Subdirectories
dirs.main = data_dir;
dirs.raw = fullfile(data_dir,'raw');
dirs.stitched = fullfile(data_dir,'stitched');
dirs.mat = fullfile(data_dir,['mat','_channel_',num2str(chan_num)]);

% If No 'raw' Directory, Create It & Move the TIF Files There
if ~exist(dirs.raw,'dir')
    mkdir(dirs.raw);
    movefile(fullfile(dirs.main,'*.tif'),dirs.raw);
end
% Create remaining directories
field_names = fieldnames(dirs);
for j=1:numel(field_names)
    if ~exist(dirs.(field_names{j}),'dir')
        mkdir(dirs.(field_names{j}));
    end
end

% Define All Filepaths Based on Data Filename
temp = dir(fullfile(dirs.raw,'*.tif'));
file_names = cell(numel(temp),1);
for j=1:numel(temp)
    file_names{j} = temp(j).name;
    paths.raw{j} = fullfile(dirs.raw,file_names{j});
    paths.mat{j} = fullfile(dirs.mat,[file_names{j}(1:end-4) '.mat']); %for .mat file
end

% Additional Paths for Metadata
paths.stackInfo = fullfile(data_dir,'stack_info.mat'); %Matfile containing image header info and tag struct for writing to TIF

%Display Paths
disp(['Data directory: ' dirs.raw]);
disp({['Path for stacks as *.mat files: ' dirs.mat];...
    ['Path for info file: ' paths.stackInfo]});