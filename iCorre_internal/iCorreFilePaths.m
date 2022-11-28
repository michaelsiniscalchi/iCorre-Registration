function [dirs, paths] = iCorreFilePaths( root_dir, data_dir, source_dir)

%Directory Structure
dirs.main = fullfile(root_dir,data_dir);
dirs.raw = fullfile(root_dir,data_dir,'raw'); %Raw data directory
dirs.source = fullfile(root_dir,data_dir,source_dir); %Default is 'raw', but can be changed to allow for seed/rigid registration->cropping->registration
dirs.mat = fullfile(root_dir,data_dir,'mat'); %temporary MAT file for pixel data ('stack') and transformations

%Path to Raw TIFFs
tiffs = dir(fullfile(dirs.raw,'*.tif'));
paths.raw = fullfile({dirs.raw}',{tiffs(:).name}');

%Temporary MAT files for working memory
paths.mat = cellfun(@(C) [C(1:end-4), '.mat'],... 
    fullfile({dirs.mat}',{tiffs.name}'),'UniformOutput', false);

%Source TIFFs for registration
tiffs = dir(fullfile(dirs.source,'*.tif')); 
paths.source = fullfile({dirs.source}',{tiffs(:).name}');

%Metadata
paths.regData = fullfile(root_dir,data_dir,'reg_info.mat'); %Matfile containing registration data
paths.stackInfo = fullfile(root_dir,data_dir,'stack_info.mat'); %Matfile containing image header info and tag struct for writing to TIF

fields = fieldnames(paths);
for i = 1:numel(fields)
    paths.(fields{i}) = string(paths.(fields{i}));
end