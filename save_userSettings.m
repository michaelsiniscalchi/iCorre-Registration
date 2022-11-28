%% Get user input to set Hyperparameters

clearvars;

% path_settings = fullfile(pwd,'user_settings.mat'); %Default user settings file; edit to specify eg a path within your data directory hierarchy
path_settings = 'W:\iCorre\_network-batch\seed\user_settings.mat';
[ params, root_dir, search_filter ] = getUserSettings(path_settings);