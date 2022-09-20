function meanProject_batch( root_dir, search_filter, params )

% Get list of data directories
if nargin<2 || ~exist("search_filter","var")
    search_filter = '';
end
data_dir = dir(fullfile(root_dir,search_filter)); %Edit to specify data directories
data_dir = {data_dir.name};
mask = ~(strcmp(data_dir,'.') | strcmp(data_dir,'..') | isfile(fullfile(root_dir,data_dir)));
data_dir = data_dir(mask); %remove '.', '..', and any files from directory list
disp('Directories for Time-Projection:');
disp(data_dir');

% Setup parallel pool for faster processing
if isempty(gcp('nocreate'))
    try
        parpool([4 128])
    catch err
        warning(err.message);
    end
end

% Load raw TIFs in parallel and save time-projections
for i = 1:numel(data_dir)
    % If No 'raw' Directory, Create It & Move the TIF Files There
    raw_dir = fullfile(root_dir,data_dir{i},'raw');
    if ~exist(raw_dir,'dir')
        mkdir(raw_dir);
        movefile(fullfile(root_dir,data_dir{i},'*.tif'),raw_dir);
    end
    stacks = dir(raw_dir);
    stacks = stacks(isfile(fullfile(raw_dir,{stacks.name})));
    %Parallel load and take mean and max projections
    parfor j = 1:numel(stacks)
        stack = loadtiffseq(fullfile(raw_dir,stacks(j).name));
        if isfield(params,'chan_num')
            stack = stack(:,:,params.chan_num:2:end);
        end
        stackMean(:,:,j) = nanmean(stack,3);

    end

end
