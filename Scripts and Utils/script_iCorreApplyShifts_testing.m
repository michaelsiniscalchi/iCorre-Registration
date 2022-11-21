clearvars;

% Apply shifts and do binned average posthoc
path_settings = 'V:\mjs20\nrmc\test\user_settings.mat'; %'V:\mjs20\nrmc\test\user_settings.mat';
params = getUserSettings(path_settings,false);
[dirs, paths] = iCorreFilePaths('V:\mjs20\nrmc','test',params.source_dir);
stackInfo = load(paths.stackInfo);

paths = iCorreApplyShifts_batch(paths, dirs, params);

%Generate binned average stacks for quality control
if params.do_stitch
    disp('Getting global downsampled stack (binned avg.) and mean projection...');
    for j = 1:numel(paths.save_tiff) %One cell per channel
        binnedAvg_batch(paths.save_tiff{j},dirs.main,stackInfo,params);
    end
end

% Movement Correction Metrics
tic;
disp('Calculating motion correction quality metrics...');
%Calculate
reg_chan = params.reg_channel;
if params.save_interleaved 
    reg_chan=[]; 
end
for j = 1:numel(paths.save_tiff) %One cell per channel
    [R, crispness, meanProj] = mvtCorrMetrics(paths.raw, paths.save_tiff{j},params.reg_channel);
    %Save results, figure, and mean projection
    [~,session_ID,~] = fileparts(dirs.main);
    save(fullfile(dirs.main,"reg_info.mat"), "R", "crispness", "meanProj","-append");
    save_multiplePlots(...
        fig_mvtCorrMetrics(session_ID, R, crispness, meanProj), dirs.main);
    saveTiff(int16(meanProj.reg), stackInfo.tags, fullfile(...
        dirs.main,[session_ID '_chan' num2str(params.reg_channel) '_stackMean.tif']));
end
%Save run time
run_times.motionCorrMetrics = toc;
disp(['Time elapsed: ' num2str(run_times.motionCorrMetrics) ' s']);
save(paths.regData,'run_times','-append'); %save correction metrics and runtime