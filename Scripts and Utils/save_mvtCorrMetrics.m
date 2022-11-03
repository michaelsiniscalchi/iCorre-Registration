function save_mvtCorrMetrics( data_dir, reg_channel )

% Movement Correction Metrics
[R, crispness, meanProj] = mvtCorrMetrics( data_dir, reg_channel );
save(fullfile(data_dir,"reg_info.mat"),"R","crispness","meanProj","-append");

%% Figures
% load(fullfile(data_dir,"reg_info.mat"),"R","crispness","meanProj");
[~,session_ID,~] = fileparts(data_dir);
fig = fig_mvtCorrMetrics(session_ID, R, crispness, meanProj);
save_multiplePlots(fig,data_dir);