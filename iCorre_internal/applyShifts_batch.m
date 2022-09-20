% function [ save_path_tiff, save_path_mat ] = applyShifts_batch(path_names, save_dir, stackInfo, chan_number, fileType_save)
function paths = applyShifts_batch(paths, dirs, stackInfo, chan_number, options)

% Check Inputs
if nargin < 5 %Default options
    fileType_save = "tiff"; %Default: save to TIFF
end
if nargin < 4
    chan_number = [];
end
%Check if filetype for save is TIFF or MAT
if ~all(strcmp(options.fileType_save,["tiff","mat"]))
    fileType_save = "tiff"; %Default: save to TIFF
    warning('applyShifts_batch.m');
    warning('options.fileType_save must be a string vector containing one or both the following: "tiff" or "mat".');
    warning('Saving stack as TIFF.');
else
    fileType_save = options.fileType_save; 
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

    %Load tiff and get channel for co-registration
    stack = loadtiffseq(paths.raw{i}); % load raw stack (.tif)
    if ~isempty(chan_number) %Check for correction based on structural channel
        stack = stack(:,:,chan_number:2:end); %Get single channel out of interleaved frames
    end
    %Crop if necessary
    if isfield(stackInfo,'margins') && ~isempty(stackInfo.margins)
        stack = cropStack(stack, stackInfo.margins);
    end

    %Load .MAT file and apply shifts from master registration
    S = load(paths.mat{i},'options','sum_shifts');
    for j = 1:numel(regParams)
        stack = apply_shifts(stack,S.sum_shifts.(regParams{j}),S.options.(regParams{j})); %apply shifts: apply_shifts(stack,shifts,options)
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
        saveTiff(stack,stackInfo.tags,fullfile(save_path_tiff(i))); %saveTiff(stack,img_info,save_path))
    end

end

paths.save_tiff = save_path_tiff;
paths.save_mat = save_path_mat;

close(h); %Close waitbar
% warning(w); %Revert warning state

