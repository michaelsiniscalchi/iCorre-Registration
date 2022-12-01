function save_mvtCorrMetrics( data_dir )

% Setup parallel pool for faster processing
if isempty(gcp('nocreate'))
    try
        parpool([4 128])
    catch err
        warning(err.message);
    end
end
tic; %Store timestamp

%Load registration info
stackInfo = load(fullfile(data_dir,'stack_info.mat'));
regInfo = load(fullfile(data_dir,'reg_info.mat'));
params = regInfo.params;

% Setup Subdirectories and File Paths
[root, sessionID] = fileparts(data_dir);
[dirs, paths] = iCorreFilePaths(root, sessionID, params.source_dir);
for j = unique([params.ref_channel, params.reg_channel])
    tiffs = dir(fullfile(dirs.main,['registered-chan' num2str(j)],'*.tif'));
    paths.save_tiff{j} = string(...
        fullfile(dirs.main,['registered-chan' num2str(j)],{tiffs.name}'));
end

% Movement Correction Metrics
disp('Calculating motion correction quality metrics...');

%Calculate and save
save_dir = 'motion-correction-metrics';
for j = 1:numel(paths.save_tiff) %One cell per channel
    [R(j), crispness(j), meanProj(j)] = ...
        mvtCorrMetrics(paths.raw, paths.save_tiff{j}, j, params.crop_margins);
    %Save results, figure, and mean projection
    save_multiplePlots(fig_mvtCorrMetrics(...
        [sessionID '_chan' num2str(j)], R(j), crispness(j), meanProj(j)),...
        fullfile(dirs.main, save_dir));
    saveTiff(int16(meanProj(j).reg), stackInfo.tags,...
        fullfile(dirs.main, save_dir, [sessionID '_chan' num2str(j) '_stackMean.tif']));
end
save(fullfile(dirs.main,"reg_info.mat"), "R", "crispness", "meanProj","-append");

%Save run time
run_times.motionCorrMetrics = toc;
disp(['Time elapsed: ' num2str(run_times.motionCorrMetrics) ' s']);
save(paths.regData,'run_times','-append'); %save correction metrics and runtime