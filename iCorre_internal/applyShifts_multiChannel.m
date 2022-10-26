% function [ save_path_tiff, save_path_mat ] = applyShifts_batch(path_names, save_dir, stackInfo, chan_number, fileType_save)
function paths = applyShifts_multiChannel(paths, dirs, stackInfo, chan_ID, params)

% Check Inputs
if ~exist("chan_ID","var") || isempty(chan_ID) %Default to one-channel
    num_chans = 1;
    chan_ID = 1;
end

if ~exist("params","var") %Default Params
    fileType_save = "tiff"; %Default: save to TIFF
    num_chans = chan_ID; %Infer multi-channel if chan_ID>1
    %Check if filetype for save is TIFF or MAT
else
    num_chans = 1 + logical(params.ref_channel); %'ref_channel' and 'reg_channel' set to 0 for 1-color imaging
    fileType_save = params.fileType_save; 
end

if ~all(ismember(fileType_save,["tiff","mat"]))
    fileType_save = "tiff"; %Default: save to TIFF
    warning('applyShifts_batch.m');
    warning('options.fileType_save must be a string vector containing one or both the following: "tiff" or "mat".');
    warning('Saving stack as TIFF.');
end

%Console display
disp('Applying shifts to follower channel...');
S = load(paths.mat{1},'options');
regParams = fieldnames(S.options);
disp('Hyperparameter sets:');
disp(regParams);

%Progress bar
h = waitbar(0,'Applying shifts...','Name','Progress');

%Initialize output var
[save_path_tiff, save_path_mat] = deal(strings(numel(paths.mat),1)); 

%Loop through registration transforms for each substack
for i = 1:numel(paths.mat)

    %Update progress bar
    temp = (i-1)/numel(paths.mat);
    msg = ['Applying shifts...  (' num2str(temp*100,2) '%)'];
    waitbar(temp,h,msg);

    %Load tiff and registration params
    stack = loadtiffseq(paths.raw{i}, params.read_method); % load raw stack (.tif)
    S = load(paths.mat{i},'options','sum_shifts');
    
    %Crop if specified
    if isfield(stackInfo,'margins') && ~isempty(stackInfo.margins)
        stack = cropStack(stack, stackInfo.margins);
    end
       
    %Apply shifts to master and/or follower channels
    for j = 1:numel(chan_ID)
        chan_out = stack(:,:,chan_ID(j):num_chans:end); %extract specified channel: 1, 2, or [1,2]
        for k = 1:numel(regParams) %for each round of registration (seed, RMC, NRMC)
            chan_out =...
                apply_shifts(chan_out,S.sum_shifts.(regParams{k}),...
                S.options.(regParams{k})); %apply shifts: apply_shifts(stack,shifts,options)
        end
        %Overwrite channel or reduce to one output channel
        if numel(chan_ID)>1 
            stack(:,:,chan_ID(j):num_chans:end) = chan_out; %preserve interleaved channels
        else
            stack = chan_out; %single channel out
        end
    end

    %Save registered stack
    [~,source,~] = fileparts(paths.raw{i});
    if any(strcmp(fileType_save,"mat")) %Save as MAT
        save_path_mat(i) = fullfile(dirs.save_mat,strcat(regParams{end},'_',source,'.mat'));
        options = S.options;
        disp(join(['Saving stack and registration info as ' save_path_mat(i) '...']));
        save(fullfile(save_path_mat(i)),'stack','options','source'); %saveTiff(stack,img_info,save_path))
    end
    if any(strcmp(fileType_save,"tiff")) %Save as TIFF
        save_path_tiff(i) = fullfile(dirs.save_tiff,strcat(regParams{end},'_',source,'.tif'));
        tags = stackInfo.tags;
        if numel(chan_ID)>1 %2-Channels for Save
            tags.ImageDescription = cell(nIFDs,1);
            [tags.ImageDescription(1:2:end), tags.ImageDescription(2:2:end)] =...
                deal(stackInfo.tags.ImageDescription{i});
        else
            tags = stackInfo.tags;
        end
        saveTiff(stack,tags,fullfile(save_path_tiff(i))); %saveTiff(stack,img_info,save_path))
    end

end

paths.save_tiff = save_path_tiff;
paths.save_mat = save_path_mat;

close(h); %Close waitbar
% warning(w); %Revert warning state

