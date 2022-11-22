clearvars;

data_dir = 'X:\michael\network-batch\nrmc\test';
[root_dir,data_dir,~] = fileparts(data_dir);

path_settings = fullfile(root_dir,data_dir,'user_settings.mat'); %'V:\mjs20\nrmc\test\user_settings.mat';
params = getUserSettings(path_settings,false);
[dirs, paths] = iCorreFilePaths(root_dir,data_dir,params.source_dir);
stackInfo = load(paths.stackInfo);
regData = load(paths.regData);
regParams = fieldnames(regData.options);

%paths = iCorreApplyShifts_batch(paths, dirs, params);
nChans = numel(unique([params.ref_channel,params.reg_channel])) - params.save_interleaved; 
[~,sourceNames,~] = fileparts(paths.source); 
for i = 1:nChans
    for j = 1:numel(sourceNames)
    paths.save_tiff{i}(j,:) = string(fullfile(dirs.main,['registered-chan' num2str(i)],...
        [regParams{end} '_' char(sourceNames(j)) '.tif']));
    end
end

% Movement Correction Metrics
tic;
disp('Calculating motion correction quality metrics...');

%Calculate and save
save_dir = 'motion-correction-metrics';
for j = 1:numel(paths.save_tiff) %One cell per channel
    [R(j), crispness(j), meanProj(j)] = ...
        mvtCorrMetrics(paths.raw, paths.save_tiff{j}, j, params.crop_margins);
    %Save results, figure, and mean projection
    save_multiplePlots(fig_mvtCorrMetrics(...
        [data_dir '_chan' num2str(j)], R(j), crispness(j), meanProj(j)),...
        fullfile(dirs.main, save_dir));
    saveTiff(int16(meanProj(j).reg), stackInfo.tags,...
        fullfile(dirs.main, save_dir, [data_dir '_chan' num2str(j) '_stackMean.tif']));
end
save(fullfile(dirs.main,"reg_info.mat"), "R", "crispness", "meanProj","-append");

%Save run time
run_times.motionCorrMetrics = toc;
disp(['Time elapsed: ' num2str(run_times.motionCorrMetrics) ' s']);
save(paths.regData,'run_times','-append'); %save correction metrics and runtime
