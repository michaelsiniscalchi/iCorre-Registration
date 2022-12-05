function appendStackInfo( batch_dir, search_filter )

% Set MATLAB search path
dirs = getRoots();
addGitRepo(dirs,'General','BrainCogs_mjs','iCorre-Registration');

% List Data Dirs for Processing
list = dir(fullfile(batch_dir, search_filter));
list = list([list.isdir] & ~ismember({list.name},{'.','..'}));
data_dir = string({list.name}');
disp(data_dir);

% Append new fields to stackInfo as needed 
for i = 1:numel(data_dir)
    
    stackInfo_file = fullfile(batch_dir,data_dir(i),'stack_info.mat');
    if exist(stackInfo_file,'file')
        stackInfo = load(fullfile(batch_dir,data_dir(i),'stack_info.mat'));
    else
        continue
    end
    
    raw_fnames = string(ls(fullfile(batch_dir,data_dir(i),'raw','*.tif')));
    if ~isfield(stackInfo,'startTime')
        [~,~,ImageDescription] =...
            loadtiffseq(fullfile(batch_dir,data_dir(i),'raw',raw_fnames(1)),1); % load raw stack (.tif)
        D = textscan(ImageDescription{1},'%s%s','Delimiter',{'='});
        stackInfo.startTime = str2num(D{2}{strcmp(D{1},'epoch ')});
        disp(['Editing stackInfo from session imaged on ' datestr(stackInfo.startTime,'yyyy-mm-dd') '...']);
        %save(fullfile(batch_dir,data_dir(i),'stack_info.mat'),'-struct','-append');
    end
end