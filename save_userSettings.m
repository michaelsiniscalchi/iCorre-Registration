%% Get user input to set Hyperparameters

clearvars;

% path_settings = fullfile(pwd,'user_settings.mat'); %Default user settings file; edit to specify eg a path within your data directory hierarchy
% path_settings = ['S:\mjs20\nrmc\user_settings.mat'];
path_settings = ['S:\mjs20\seed\user_settings.mat'];
% path_settings = ['S:\mjs20\seed\230922-m105-maze7-test\user_settings.mat'];
params = getUserSettings(path_settings);