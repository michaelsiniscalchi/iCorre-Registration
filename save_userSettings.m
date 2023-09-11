%% Get user input to set Hyperparameters

clearvars;

% path_settings = fullfile(pwd,'user_settings.mat'); %Default user settings file; edit to specify eg a path within your data directory hierarchy
path_settings = ['Y:\michael\230907-M103-test\user_settings.mat'];
% path_settings = ['S:\mjs20\seed\user_settings.mat'];
params = getUserSettings(path_settings);