%% start_batchProcessing
%Purpose: Script to batch process 1- or 2-channel imaging stacks. Included
%   functions correct rigid and non-rigid movement artifacts using a flexible
%   recursive approach.
%
%Author: MJ Siniscalchi, 171212
%
%
%To determine the needed files/MATLAB packages, run these three lines in the console:
%
%[fList,pList] = matlab.codetools.requiredFilesAndProducts('start_batchProcessing.m');
%{fList{:}}'
%{pList.Name}'
%
%Edits:
%   180709mjs Began rewrite for registration directly from raw TIF files
%               (previous ver required pre-stitching)
%   Future: option for co-registering two functional channels (current version 
%       only outputs stacks as TIF for one channel)
%
%--------------------------------------------------------------------------
clearvars;

%Search filter for finding data directories
search_filter = '*M62*'; %wildcard syntax; if none, do not include stars

%<<FUTURE: CREATE USER INTERFACE FOR OBTAINING THESE VALUES)>>
%Set Parameters for iterative correction, if applicable 
params.nIter = [0,0,0]; %Fixed n-iterations for each run; [seed,rigid,nonrigid] Set >0 only if not using auto iteration (some stacks failed with assorted errors)
params.max_reps = [1,3,10]; %maximum number of repeats for auto iteration; set each to 1 or 0 for fixed # iterations (and set params.nIter>0).
params.max_err = 1; %threshold abs(dx)+abs(dy) per frame [TROUBLESHOOT - save max(err) for each iter]
params.nFrames_seed = 1000; %nFrames to AVG for for initial ref image (must be < nFrames; 1000 works well of 256x256 galvo data)

params.split_channels.ref_channel = 0; %1=red (tdTomato/structural or if 2-color functional), 2=green to ignore red channel, 0 if 1-color imaging
params.split_channels.reg_channel = 0; %2=green (GCaMP/physiological), 0 if 1-color imaging

params.do_stitch = true;   %Global binned average stack and max projection for quality control.
params.bin_width = 1;   %For binned average; set to 1 to stitch a non-downsampled stack. 

params.delete_mat = true;  %Delete .MAT files after writing .TIFs (keep if desired for troubleshooting, alt. formats, etc.)

%Specify corresponding directories:
root_dir =  'C:\Users\Michael\Documents\Data & Analysis\Processing Pipeline\2 iNoRMCorre 1Chan';
%root_dir = 'C:\Users\Michael\Documents\Data & Analysis\Processing Pipeline\2 iNoRMCorre R2G';
%root_dir = 'C:\Users\Michael\Documents\Data & Analysis\Processing Pipeline\2 iNoRMCorre G2G';

%Paths to required toolboxes
addpath(genpath('C:\Users\Michael\Documents\MATLAB\iCorre Registration')); %Location of iCorre Registration directory

%% Batch movement correction
[status,msg] = iCorre_batch(root_dir,search_filter,params); %iCorre_batch(root_dir,search_filter,params)

%***FUTURE: generate stackInfo.mat
%Use code from StitchTiffs_greenChan.m