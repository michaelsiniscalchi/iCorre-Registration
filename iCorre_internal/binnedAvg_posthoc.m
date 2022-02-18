%%% Stitch registered files for QC post-hoc 
%
%   -Purpose: To stitch downsampled file from registered stacks, saved in
%   either TIF or MAT format.
%   -
%---------------------------------------------------------------------------------------------------
clearvars;

%--- Setup parameters for stitching TIFFs ----------------------------------------------------------

root_dir = 'C:\Data\2-Photon Imaging';
save_dir = 'stitched'; %Blank for parent dir
params.scim_ver = 5;
stitch_chan = 1; %Set to 0 for registered (1-channel) tiffs
bin_width = 30;

%---------------------------------------------------------------------------------------------------

[fname,fpath] = uigetfile(fullfile(root_dir,'*.*'),'Select One or More Files to Stitch and Downsample','MultiSelect', 'on');
for i = 1:numel(fname)
    stack_path{i} = fullfile(fpath,fname{i});
end

%Setup save directory and get filetype
data_dir = fullfile(fpath,'..\.'); %Parent of fpath
create_dirs(fullfile(data_dir,save_dir)); %Create dirs if non-existent
save_dir = fullfile(data_dir,save_dir);
[~,~,ext] = fileparts(fname{1});

if strcmp(ext,'.mat')
    stackInfo = load(stack_path{i},'tags');
    for i=1:numel(stack_path)
        matObj = matfile(stack_path{i});
        stackInfo.nFrames(i) = size(matObj.stack,3);
    end
    stackInfo.imageHeight = stackInfo.tags.ImageLength;
    stackInfo.imageWidth = stackInfo.tags.ImageWidth;
elseif isfile(fullfile(data_dir,'stack_info.mat')) %If file exists
    stackInfo = load(fullfile(data_dir,'stack_info.mat'));
else %Extract stack info and convert
    %Setup directory structure
    [ dirs, paths ] = setup_stitchDirs( data_dir, stitch_chan );
    % Load raw TIFs and convert to MAT for further processing
    disp('Converting *.TIF files to *.MAT...');
    info_path = fullfile(data_dir,'stack_info.mat');
    stackInfo = get_imgInfo(paths.raw, params); %Extract header info from image stack (written by ScanImage)
    stackInfo.tags = tiff2mat(stack_path, paths.mat, stitch_chan); %Batch convert all TIF stacks to MAT and get info.
    stack_path = paths.mat;
    save(paths.stackInfo,'-STRUCT','stackInfo','-v7.3');
end

%If TIF is specified with Channel Number (eg for stitching raw imaging data)
[pathname,filename,ext] = fileparts(stack_path{1});
if stitch_chan && strcmp(ext,'.tif')
    %Setup directory structure
    [ ~, paths ] = setup_stitchDirs( data_dir, stitch_chan );
    tiff2mat(stack_path, paths.mat, stitch_chan); %Batch convert all TIF stacks to MAT and get info.
    stack_path = paths.mat;
end

%Save downsampled TIF in 'stitched' folder
binnedAvg_batch(stack_path,save_dir,stackInfo,bin_width);