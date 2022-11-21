function fullpath_save = iCorreApplyShifts(path_source, path_mat, path_save, chan_ID, crop_margins, save_interleaved)

%Load specified channel(s) from source TIFF
channel = chan_ID;
if numel(channel)>1
    channel = []; %Load all IFDs
end
stack = loadtiffseq(path_source, channel); % load raw stack (.tif) as cell

% Crop if specified
if ~isempty(crop_margins)
    stack = cropStack(stack, crop_margins);
end

% Apply shifts to master and/or follower channels
S = load(path_mat,'options','sum_shifts','source','tags');
reg_params = fieldnames(S.options); %ie, {'seed','RMC','NRMC'}
for j = 1:numel(chan_ID)
    %Apply shifts from each round of registration (seed, RMC, NRMC)
    for k = 1:numel(reg_params)
        stack(:,:,j:numel(chan_ID):end) = apply_shifts(... %Isolate specified channel if interleaved
            stack(:,:,j:numel(chan_ID):end),...
            S.sum_shifts.(reg_params{k}),...
            S.options.(reg_params{k})); %apply shifts: apply_shifts(stack,shifts,options)
    end
end

% Save Registered Stack into Specified Output Channels
nChans = numel(chan_ID) - save_interleaved; 
for j = 1:nChans
    fullpath_save(j) = string(fullfile(path_save{j},[reg_params{end} '_' S.source])); %#ok<AGROW>
    saveTiff(stack(:,:,j:nChans:end), S.tags, fullpath_save(j)); %saveTiff(stack,img_info,save_path))
end