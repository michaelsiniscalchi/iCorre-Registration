function applyShifts_posthoc(root_dir, search_filter)

% Save registered stacks as TIFF using raw data and shifts from MAT files

%% Get list of data directories
if nargin<2 || ~exist("search_filter","var")
    search_filter = '';
end
temp = dir(fullfile(root_dir, search_filter)); %Edit to specify data directories
data_dirs = {temp.name};
temp = ~(strcmp(data_dirs,'.') | strcmp(data_dirs,'..') | isfile(fullfile(root_dir,data_dirs)));
data_dirs = data_dirs(temp); %remove '.', '..', and any files from directory list
disp('Directories for movement correction:');
disp(data_dirs');

%% Setup parallel pool for faster processing
if isempty(gcp('nocreate'))
    try
        parpool([4 128])
    catch err
        warning(err.message);
    end
end

%% Loop through all matching data directories
for i=1:numel(data_dirs)
    try
        %Load imaging and registration info
        [dirs, paths, stackInfo, params] = getRegData(data_dirs{i});

        % --- Apply registration to follower and/or reference channel as needed ---
        applyShiftsTime = tic;
        if params.preserve_chans
            %2-Channel: Apply Shifts and Save Stacks in Original Channel Order
            %paths = applyShifts_multiChannel(paths, dirs, stackInfo, chan_ID, params)
            paths = applyShifts_multiChannel(...
                paths, dirs, stackInfo, [1,2], params); %Apply shifts and save .TIF files
        elseif params.ref_channel %set to 0 for 1-channel imaging
            %2-Channel: Apply Shifts and Save One Channel
            paths = applyShifts_multiChannel(...
                paths, dirs, stackInfo, params.reg_channel, params); %Apply shifts and save .TIF files
        else
            %1-Channel: Save Registered Stacks as .TIF
            paths  = applyShifts_multiChannel(paths, dirs, stackInfo, 1, params); %Apply shifts and save .TIF files
        end
        applyShiftsDuration = toc(applyShiftsTime);
        disp(['Time spent applying shifts to output channel(s): ' num2str(applyShiftsDuration) ' s']);

        % --- Stitch entire (downsampled) session as one TIFF ---
        if params.do_stitch
            bin_width = params.bin_width;
            if params.preserve_chans %Binned Avg includes both channels, eg, for use in cropping
                stackInfo.nFrames = 2*stackInfo.nFrames;
                bin_width = 2*bin_width;
            elseif params.ref_channel
                disp('Getting global downsampled stack (binned avg.) and max projection from registered reference channel...');
                binnedAvg_batch(paths.mat,dirs.save_ref,stackInfo,bin_width); %Save binned avg and projection to ref-channel dir
            end
            disp('Getting global downsampled stack (binned avg.) and max projection of (co-)registered frames...');
            binnedAvg_batch(paths.save_tiff,dirs.main,stackInfo,bin_width); %Save binned avg and projection to main data dir
        end

        run_times.saveTif = toc(applyShiftsTime);
        disp(['Total time for saving registered data: ' num2str(run_times.saveTif) ' s']);
        save(paths.regData,'run_times','-append'); %save parameters

        % --- Movement Correction Metrics ---
        tic;
        disp('Calculating motion correction quality metrics...');
        %Calculate
        [R, crispness, meanProj] = mvtCorrMetrics(data_dirs{i}, params.reg_channel);
        %Save results, figure, and mean projection
        [~,session_ID,~] = fileparts(dirs.main);
        save(fullfile(data_dirs{i},"reg_info.mat"), "R", "crispness", "meanProj","-append");
        save_multiplePlots(...
            fig_mvtCorrMetrics(session_ID, R, crispness, meanProj), data_dirs{i});
        saveTiff(meanProj, stackInfo.tags, fullfile(...
            save_dir,[session_ID '_chan' num2str(params.reg_channel) '_stackMean.tif']));
        %Save run time
        run_times.motionCorrMetrics = toc;
        disp(['Time elapsed: ' num2str(run_times.motionCorrMetrics) ' s']);
        save(paths.regData,'run_times','-append'); %save correction metrics and runtime


        %% Remove stacks from saved MAT files 
        if params.delete_mat
            removeStackData_par(paths.mat);
        end

    catch err
        disp(err);
        disp([{err.stack.name}',{err.stack.line}']);
    end %end try

    if ~exist('err','var')
        status(i) = true;
        err_msg{i} = [];
    else
        status(i) = false;
        err_msg{i} = err;
        if exist(paths.regData,'file')
            save(paths.regData,'err_msg','-append'); %save error msg
        else
            save(paths.regData,'err_msg'); %save error msg
        end
    end

    clearvars '-except' root_dir data_dirs params i status err_msg;
end %end <<for i=1:numel(data_dirs)>>