function [dirs, paths] = iCorreFilePaths( root_dir, data_dir, source_dir)

%Directory Structure
dirs.main = fullfile(root_dir,data_dir);
dirs.raw = fullfile(root_dir,data_dir,'raw'); %Raw data directory
dirs.source = fullfile(root_dir,data_dir,source_dir); %Default is 'raw', but can be changed to allow for seed/rigid registration->cropping->registration
dirs.mat = fullfile(root_dir,data_dir,'mat'); %temporary MAT file for pixel data ('stack') and transformations
dirs.registered = fullfile(root_dir,data_dir,'registered-chan1'); %Registered data directory for channel-1

%Path to Raw TIFFs
tiffs = dir(fullfile(dirs.raw,'*.tif'));
[~, idx] = sort([tiffs.datenum]);
paths.raw = fullfile({dirs.raw}',{tiffs(idx).name}');

%Temporary MAT files for working memory
paths.mat = cellfun(@(C) [C(1:end-4), '.mat'],... 
    fullfile({dirs.mat}',{tiffs.name}'),'UniformOutput', false);

%Source TIFFs for registration
tiffs = dir(fullfile(dirs.source,'*.tif')); 
paths.source = fullfile({dirs.source}',{tiffs(:).name}');

%Registered Data from Channel 1 and/or 2, if existent
reg_dir = {...
    fullfile(root_dir,data_dir,'registered-chan1'); 
    fullfile(root_dir,data_dir,'registered-chan2')};
for i = 1:2
    tiffs = dir(fullfile(reg_dir{i},'*.tif'));
    paths.registered{i} = string(fullfile(reg_dir(i)',{tiffs(:).name}'));
end

%Metadata
paths.regData = fullfile(root_dir,data_dir,'reg_info.mat'); %Matfile containing registration data
paths.stackInfo = fullfile(root_dir,data_dir,'stack_info.mat'); %Matfile containing image header info and tag struct for writing to TIF

% Convert all fullfile paths to string arrays
fields = fieldnames(paths);
fields = fields(~ismember(fields,{'regData','stackInfo','registered'}));
for i = 1:numel(fields)
    paths.(fields{i}) = string(paths.(fields{i}));
end