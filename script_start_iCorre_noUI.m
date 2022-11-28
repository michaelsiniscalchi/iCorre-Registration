%% For use on the High-Perfomance Clusters, etc.

root_dir = 'Y:\Michael\_testing';
code_dir = 'Y:\Michael\_code\iCorre-Registration';
search_filter = '*test*'; %With wildcards

%Go to iCorre-Registration Repo directory
addpath(genpath(pwd)); 

%If user_settings in batch dir or data subdir
iCorre_batch(root_dir,search_filter);

%If user settings somewhere else
% params = load(fullfile(settings_dir,'user_settings.mat')); 
% iCorre_batch(root_dir,search_filter,params);

%To configure and save hyperparameters 
%(user_settings MAT file will be saved at specified location)
% params = getUserSettings('Y:\Michael\_testing\user_settings.mat',true); 
 
