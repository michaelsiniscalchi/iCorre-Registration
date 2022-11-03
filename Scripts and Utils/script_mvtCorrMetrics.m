
data_dir = 'C:\Data\TaskLearning_VTA\data\220309 M413 T6_test';
[~,session_ID,~] = fileparts(data_dir);
reg_channel = 1;

% Movement Correction Metrics
[R, crispness, meanProj] = mvtCorrMetrics( data_dir, reg_channel );
save(fullfile(data_dir,"reg_info.mat"),"R","crispness","meanProj","-append");

%% Figures
% data_dir = "C:\Data\TaskLearning_VTA\data\220309 M413 T6_test";
% load(fullfile(data_dir,"reg_info.mat"),"R","crispness","meanProj");
% [~,session_ID,~] = fileparts(data_dir);
fig = fig_mvtCorrMetrics(session_ID, R, crispness, meanProj);
save_multiplePlots(fig,data_dir);