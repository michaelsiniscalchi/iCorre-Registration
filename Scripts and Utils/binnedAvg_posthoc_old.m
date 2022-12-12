%%% Stitch registered files for QC post-hoc 
%
%   -Purpose: To stitch downsampled file from registered stacks, saved in
%   either TIF or MAT format.
%   -
%---------------------------------------------------------------------------------------------------
clearvars;

%--- Setup parameters for stitching TIFFs ----------------------------------------------------------

root_dir = 'C:\Data\2-Photon Imaging';
save_dir = []; %[] for parent dir
bin_width = 30;

options.chan_number     = 0; %For interleaved 2-color imaging; channel to convert. Set to 0 for registered (1-channel) tiffs.
options.crop_margins    = [];
options.save_mat        = false; %Option to save substacks and stackInfo as MAT
%---------------------------------------------------------------------------------------------------

%User-select files for stitch/downsample
[fname,fpath] = uigetfile(fullfile(root_dir,'*.*'),'Select One or More Files to Stitch and Downsample','MultiSelect', 'on');
for i = 1:numel(fname)
    stack_path{i} = fullfile(fpath,fname{i});
end

%Setup save directory
data_dir = fullfile(fpath,'..\.'); %Parent of fpath
create_dirs(fullfile(data_dir,save_dir)); %Create dirs if non-existent
save_dir = fullfile(data_dir,save_dir);
%Get filetype
[~,~,ext] = fileparts(fname{1});

%Extract image stack information
if strcmp(ext,'.mat')
    stackInfo = load(stack_path{i},'tags');
    for i=1:numel(stack_path)
        matObj = matfile(stack_path{i});
        stackInfo.nFrames(i,1) = size(matObj.stack,3);
    end
    stackInfo.imageHeight = stackInfo.tags.ImageLength;
    stackInfo.imageWidth = stackInfo.tags.ImageWidth;

elseif options.save_mat
    %Setup directory structure
    [ ~, paths ] = setup_stitchDirs( data_dir, options.chan_number );
    % Load raw TIFs and convert to MAT for further processing
    disp('Converting *.TIF files to *.MAT...');
    stackInfo = tiff2mat(stack_path, paths.mat, options); %Batch convert all TIF stacks to MAT and get info.
    stack_path = paths.mat;
    save(paths.stackInfo,'-STRUCT','stackInfo','-v7.3');
else %Must have pre-saved stack_info.mat
    stackInfo = load(fullfile(data_dir,'stack_info.mat'));
end

%Downsample TIF and save in specified folder
binnedAvg_batch(stack_path,save_dir,stackInfo,bin_width);