function [ dirs, paths, stackInfo, params ]  = getRegData(data_dir)

% Define & Create Subdirectories
dirs.main = data_dir;
dirs.raw = fullfile(data_dir,'raw');
dirs.mat = fullfile(data_dir,'mat'); %For read/write during registrationdirs.save_tiff = fullfile(data_dir,'registered tiff'); %To save registered stacks as TIFF
dirs.save_mat = fullfile(data_dir,'registered mat'); %To save registered stacks as TIFF
dirs.save_tiff = fullfile(data_dir,'registered tiff'); %To save registered stacks as TIFF

% Load Image Stack Info and Registration Data
stackInfo = load(fullfile(dirs.main,'stack_info.mat'));
load(fullfile(dirs.main,'reg_info.mat'),'params');

if params.ref_channel~=params.reg_channel && params.do_stitch %If two-color co-registration
    dirs.save_ref = fullfile(data_dir,'registered ref channel'); %Save dir for registered reference channel
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
paths.regData = fullfile(data_dir,'reg_info.mat'); %Matfile containing registration data
paths.stackInfo = fullfile(data_dir,'stack_info.mat'); %Matfile containing image header info and tag struct for writing to TIF

%Display Paths
disp(['Raw Data directory: ' dirs.raw]);
disp({['Path for stacks as *.mat files: ' dirs.mat];...
    ['Path for info file: ' paths.regData]});
