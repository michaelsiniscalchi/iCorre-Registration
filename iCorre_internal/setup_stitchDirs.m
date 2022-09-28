function [ dirs, paths ] = setup_stitchDirs( data_path, chan_num )

% Define & Create Subdirectories
if iscell(data_path) && isfile(data_path{1})
    [~,file_names] = fileparts(data_path);
    dirs.main = fullfile(fileparts(data_path{1}),'..\.'); %Parent of fpath
elseif isstring(data_path) || ischar(data_path) %Arg 1 is main data directory
    dirs.main = data_path;
end
dirs.raw = fullfile(dirs.main,'raw');
dirs.stitched = fullfile(dirs.main,'stitched');
dirs.mat = fullfile(dirs.main,['mat','_channel_',num2str(chan_num)]);

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

% Get Data Filenames if not directly specified
if ~exist("file_names", "var")
    temp = dir(fullfile(dirs.raw,'*.tif'));
    file_names = cell(numel(temp),1);
    for j=1:numel(temp)
        file_names{j} = temp(j).name(1:end-4);
    end
end
% Define All Filepaths Based on Data Filenames
for j = 1:numel(file_names)
    paths.raw{j} = fullfile(dirs.raw,[file_names{j},'.tif']);
    paths.mat{j} = fullfile(dirs.mat,[file_names{j},'.mat']); %for .mat file
end


% Additional Paths for Metadata
paths.stackInfo = fullfile(dirs.main,'stack_info.mat'); %Matfile containing image header info and tag struct for writing to TIF

%Display Paths
disp(['Data directory: ' dirs.raw]);
disp({['Path for stacks as *.mat files: ' dirs.mat];...
    ['Path for info file: ' paths.stackInfo]});