function appendStackInfo( batch_dir, search_filter )

% Set path
dirs = getRoots();
addGitRepo(dirs,'General','BrainCogs_mjs','iCorre-Registration');

%Run basic behavioral processing for each imaging session
list = dir(fullfile(batch_dir, ['*' search_filter '*']));
list = list([list.isdir] & ~ismember({list.name},{'.','..'}));
data_dir = string({list.name}');
for i = 1:numel(data_dir)
    stackInfo = load(fullfile(batch_dir,data_dir(i),'stack_info.mat')); 
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