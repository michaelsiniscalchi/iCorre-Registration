%%Stitch registered files for QC post-hoc 
%   -needed, e.g., when specified stitched downsampled file is too big for TIF format (~4GB)
%
clearvars;

data_dir = uigetdir('C:\Users\Michael\Documents\Data & Analysis\Processing Pipeline');
bin_width = 2;

cd(data_dir);
stack_path = uigetfile(fullfile(data_dir,'*.tif'),'Select One or More Files','MultiSelect', 'on');
load('regInfo.mat','stackInfo');

binnedAvg_batch(stack_path,data_dir,stackInfo,bin_width);