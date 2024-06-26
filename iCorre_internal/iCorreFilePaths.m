function [dirs, paths] = iCorreFilePaths( root_dir, data_dir, source_dir)

%Directory Structure
dirs.main = fullfile(root_dir,data_dir);
dirs.raw = fullfile(root_dir,data_dir,'raw'); %Raw data directory
dirs.source = fullfile(root_dir,data_dir,source_dir); %Default is 'raw', but can be changed to allow for seed/rigid registration->cropping->registration
dirs.mat = fullfile(root_dir,data_dir,'mat'); %temporary MAT file for pixel data ('stack') and transformations

%Metadata
paths.regData = fullfile(root_dir,data_dir,'reg_info.mat'); %Matfile containing registration data
paths.stackInfo = fullfile(root_dir,data_dir,'stack_info.mat'); %Matfile containing image header info and tag struct for writing to TIF



%Path to Raw TIFFs
tiffs = dir(fullfile(dirs.raw,'*.tif'));
[~, idx] = sort([tiffs.datenum]);
paths.raw = fullfile({dirs.raw}',{tiffs(idx).name}');

%Temporary MAT files for working memory
paths.mat = string(cellfun(@(C) [C(1:end-4), '.mat'],... 
    fullfile({dirs.mat}',{tiffs.name}'),'UniformOutput', false));

%Source TIFFs for registration
tiffs = dir(fullfile(dirs.source,'*.tif')); 
paths.source = string(fullfile({dirs.source}',{tiffs(:).name}'));

%Paths to Registered TIFFs
if exist(paths.regData,"file")
    s = load(paths.regData,'params'); %Check for 2-color imaging
    dirs.registered = fullfile(root_dir,data_dir,['registered-chan',... %registered data directory
        num2str(max([~isempty(s.params.reg_channel), s.params.reg_channel]))]); %channel idx (0 for 1-color imaging)
    
    %Registered Data from Channel 1 and/or 2, if existent
    tiffs = dir(fullfile(dirs.registered,'*.tif'));
    paths.registered = string(fullfile({dirs.registered}',{tiffs(:).name}'));

    %FUTURE: use fields from options or nRepeats to name folder (+
    %chan_num), to separate RMC and NRMC results...
    %Maybe internal to iCorre_batch???

end

% Convert all fullfile paths to string arrays
fields = fieldnames(paths);
fields = fields(~ismember(fields,{'regData','stackInfo','registered'}));
for i = 1:numel(fields)
    paths.(fields{i}) = string(paths.(fields{i}));
end