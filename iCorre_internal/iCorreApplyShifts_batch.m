function paths = iCorreApplyShifts_batch(paths, dirs, params)

%Extract channel IDs to register
if params.save_ref || params.save_interleaved %Register both channels
    chan_ID = [1,2];
elseif params.ref_channel %Register only the follower channel
    chan_ID = params.reg_channel;
else %Single-channel imaging    
    chan_ID = 1;
end

%Create save directories
if params.save_interleaved
    path_save = {fullfile(dirs.main,"registered-interleaved")}; %Stored in cell for multiple channels as below
else
    for i = 1:numel(chan_ID)
        path_save{i} = fullfile(dirs.main,string(['registered-chan' num2str(chan_ID(i))])); %#ok<*AGROW>
    end
end
create_dirs(path_save{:});

%Unpack variables from struct for parallel processing
path_source = paths.source;
mat_path = paths.mat;
crop_margins = params.crop_margins;
save_interleaved = params.save_interleaved;

%Loop through registration transforms for each substack
disp('Applying shifts and saving to:');
disp(path_save);
parfor i = 1:numel(path_source) %PARFOR
    path_save_tiff(i,:) = iCorreApplyShifts(path_source{i}, mat_path{i}, path_save,...
        chan_ID, crop_margins, save_interleaved); 
end

%Output filepaths for each channel 
% path_save_tiff = cat(1,path_save_tiff{:});
for i = 1:size(path_save_tiff,2)
    paths.save_tiff{i} = path_save_tiff(:,i);
end