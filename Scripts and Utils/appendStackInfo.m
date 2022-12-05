function appendStackInfo( batch_dir, search_filter )

% Set MATLAB search path
dirs = getRoots();
addGitRepo(dirs,'General','BrainCogs_mjs','iCorre-Registration');

% List Data Dirs for Processing
disp('Data Directories for Processing:')
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

    raw_tiffs = dir(fullfile(batch_dir,data_dir(i),'raw','*.tif'));

    %Record session start-time
    if ~isfield(stackInfo,'startTime')
        disp(['Getting session start-time from Tiff #1: ' raw_tiffs(1).name])
        [~,~,ImageDescription] =...
            loadtiffseq(fullfile(batch_dir,data_dir(i),'raw',raw_tiffs(1).name),1); % load raw stack (.tif)
        D = textscan(ImageDescription{1},'%s%s','Delimiter',{'='});
        stackInfo.startTime = str2num(D{2}{strcmp(D{1},'epoch ')});
    end

    %Record raw filenames
    if ~isfield(stackInfo,'rawFileNames')
        disp('Adding Field "rawFileNames"...');
        [~,I] = sort([raw_tiffs(:).datenum]);
        stackInfo.rawFileNames = string({raw_tiffs(I).name}');
        disp('File Names:'); disp(stackInfo.rawFileNames);
    end

    %Remove old field 'rawFileName'
    if isfield(stackInfo,'rawFileName')
        disp('Removing obsolete field "rawFileName"');
        stackInfo = rmfield(stackInfo,'rawFileName');
    end

    %Save data structure
    disp(['Editing stackInfo from session imaged on ' datestr(stackInfo.startTime,'yyyy-mm-dd') '...']);
    save(fullfile(batch_dir,data_dir(i),'stack_info.mat'),'-struct','stackInfo');
end