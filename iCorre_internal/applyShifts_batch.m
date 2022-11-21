function paths = applyShifts_batch(paths, dirs, stackInfo, params)

% Check Inputs
S = load(paths.mat{1},'options');
reg_params = fieldnames(S.options);

%Extract channel IDs to register
if params.save_ref || params.preserve_chans
    %Register both channels
    chan = [];
    chan_ID = [1,2];
elseif params.ref_channel
    %Register only the follower channel
    [chan, chan_ID] = deal(params.reg_channel);
else
    %Single-channel imaging
    chan = [];
    chan_ID = 1;
end

%Create save directories
[~,fnames,~] = fileparts(paths.raw);
prefix = repmat(reg_params(end),numel(fnames),1);
if params.save_interleaved
    dirs.save_tiff = fullfile(dirs.main,'registered-interleaved');
else
    for i = 1:numel(chan_ID)
        dirs.save_tiff{i} = fullfile(dirs.main,['registered-chan' num2str(chan_ID(i))]);
    end
end

%Save paths
for i = 1:numel(dirs.save_tiff)
    path_save{i} = fullfile(dirs.save_tiff{i}, join([prefix,fnames],'_')); %#ok<AGROW> 
end
path_save = horzcat(path_save{:});

%Unpack variables for parallel processing
path_source = paths.source;
mat_path = paths.mat;
crop_margins = params.crop_margins;
save_interleaved = params.save_interleaved;
tags = rmfield(stackInfo.tags,'ImageDescription'); %ImageDescription not needed; save memory!

%Loop through registration transforms for each substack
parfor i = 1:numel(path_source)
iCorreApplyShifts(path_source{i}, mat_path{i}, path_save(i,:), reg_params, chan_ID, crop_margins, save_interleaved, tags);
end

% %         disp(['Applying shifts to channel ' num2str(P.chan_ID(j)) '...']);
% %         disp('Hyperparameter sets:');
% %         disp(regParams);    
% 
%     stack = loadtiffseq(paths.source{i}, chan, params.read_method); % load raw stack (.tif) as cell
%     S = load(paths.mat{i},'options','sum_shifts');
% 
%     % Crop if specified
%     if isfield(stackInfo,'margins') && ~isempty(stackInfo.margins)
%         stack = cropStack(stack, stackInfo.margins);
%     end
% 
%     % Apply shifts to master and/or follower channels
%     for j = 1:numel(chan_ID)
%         disp(['Applying shifts to channel ' num2str(chan_ID(j)) '...']);
%         disp('Hyperparameter sets:');
%         disp(regParams);
% 
%         %Apply shifts from each round of registration (seed, RMC, NRMC)
%         chan_out = stack(:,:,j:numel(chan_ID):end); %Isolate specified channel if interleaved
%         for k = 1:numel(regParams)
%             chan_out =...
%                 apply_shifts(chan_out,S.sum_shifts.(regParams{k}),...
%                 S.options.(regParams{k})); %apply shifts: apply_shifts(stack,shifts,options)
%         end
% 
%         %Overwrite channel
%         stack(:,:,j:numel(chan_ID):end) = chan_out; %preserve interleaved channels
%     end
%     clearvars chan_out
% 
%     %Split channels if necessary
%     if numel(chan_ID)>1 && ~params.preserve_chans
%         stack_out{1} = stack(:,:,1:2:end);
%         stack_out{2} = stack(:,:,2:2:end);
%     else
%         stack_out = {stack};
%     end
%     clearvars stack
% 
%     % Save Registered Stack(s)
%     [~,source,~] = fileparts(paths.raw{i});
% 
%     for j = 1:numel(stack_out)
%         %Save as TIFF
%         stack = stack_out{j};
%         if any(strcmp(params.fileType_save,"tiff")) %Save as TIFF
%             save_path_tiff{j}(i) = ...
%                 fullfile(dirs.save_tiff{j},strcat(regParams{end},'_',source,'.tif'));
%             tags = stackInfo.tags;
%             if params.preserve_chans %Save interleaved
%                 tags.ImageDescription = cell(size(stack,3),1);
%                 [tags.ImageDescription(1:2:end), tags.ImageDescription(2:2:end)] =...
%                     deal(stackInfo.tags.ImageDescription{i});
%             else
%                 tags = stackInfo.tags;
%             end
%             saveTiff(stack,tags,fullfile(save_path_tiff{j}(i))); %saveTiff(stack,img_info,save_path))
%         end
%     end

end
% 
% paths.save_tiff = save_path_tiff;
% paths.save_mat = save_path_mat;
