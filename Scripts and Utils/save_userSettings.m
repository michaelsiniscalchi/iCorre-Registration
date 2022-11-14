%% start_iCorre
%
%Purpose: Script to process any number of 1- or 2-channel imaging stacks. Included
%   functions correct rigid and non-rigid movement artifacts using a flexible
%   recursive approach.
%
%Author: MJ Siniscalchi, 171212
%
%SETUP:
%       (1) To determine the needed files/MATLAB packages, add the main repository and all 
%           subdirectories to the path. Then run these three lines in the console:
%           [fList,pList] = matlab.codetools.requiredFilesAndProducts('start_iCorre.m');
%           {fList{:}}'
%           {pList.Name}'
%       (2) Download and install the necessary MATLAB components. Local toolboxes are included in 
%               the repository found at https://github.com/michaelsiniscalchi/iCorre-Registration
%       (3) Run this script to begin. Set hyperparameters using the dialog box.  
%
%   NOTES: 
%       *BATCH PROCESSING: iCorre_batch can register image stacks from multiple data directories back-to-back.
%       *Specify batch processing by entering full path to batch directory (parent dir. to data dirs.).
%       *Set SEARCH FILTER to specify a subset of data directories within batch directory.
%
%EDITS:
%   180709mjs Began rewrite for registration directly from raw TIF files 
%           (previous version required concatenation prior to movement correction)
%   220203mjs Implemented reference image based on frames with top 20%
%           pixel correlation. (Carson Stringer's suggestion).
%
%--------------------------------------------------------------------------
clearvars;

%% Get user input to set Hyperparameters
% path_settings = fullfile(pwd,'user_settings.mat'); %Default user settings file; edit to specify eg a path within your data directory hierarchy
path_settings = 'V:\mjs20\nrmc\test\user_settings.mat';
[ params, root_dir, search_filter ] = getUserSettings(path_settings);