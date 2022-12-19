%% Get user input to set Hyperparameters

clearvars;

% path_settings = fullfile(pwd,'user_settings.mat'); %Default user settings file; edit to specify eg a path within your data directory hierarchy
path_settings = ['V:\mjs20\nrmc\220323 M411 T6 pseudorandom\user_settings.mat'];
params = getUserSettings(path_settings);