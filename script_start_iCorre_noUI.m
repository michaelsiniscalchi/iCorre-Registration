%% For use on the High-Perfomance Clusters, etc.

root_dir = 'Y:\Michael\_testing';
search_filter = '*test*'; %With wildcards

addpath(genpath(pwd)); 
% params = load(fullfile(root_dir,'user_settings.mat')); 
iCorre_batch(root_dir,search_filter);

%% To configure and save hyperparameters 
% [~, ~, params] = getUserSettings('Y:\Michael\_testing\user_settings.mat',true); 
% [~, ~, params] = getUserSettings('W:\iCorre-test\Data\user_settings.mat',true); 
