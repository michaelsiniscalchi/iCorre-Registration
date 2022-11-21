%%% iCorre_batch
%PURPOSE: Script for iterative implementation of NoRMCorre (non-rigid movement correction),
%   with option to apply correction based on a separate anatomical reference channel.
%AUTHOR: MJ Siniscalchi, from tools developed by EA Pnevmatikakis (Flatiron Institute, Simons Foundation)
%DATE: 180718
%
%INPUTS
%   string root_dir:        Main directory containing all data directories to process.
%   string search_filter:   Wildcard string used to define data directory names within root_dir, e.g., '*RuleSwitching*'.
%   struct params:          Iterative movement correction parameters.
%       fields {'max_reps','max_err','nFrames_seed'}(see <<Set Parameters>> below).
%
%OUTPUTS
%   logical status:     Logical mask for successfully processed data directories.
%   cell msg:           Any associated error messages, indexed according to data directory.
%
%NOTES
%   --  Occasionally, writing to a working MAT file fails during
%       registration, throwing this error: 'MATLAB:save:permissionDenied'
%       If problem persists, try checking attributes and pausing
%       before save...
%
%   **TO DO:
%       -- assign separate dirs.save_reg, dirs.save_ref, dirs.save_interleaved (registered-chan1, registered-chan0, registered-interleaved, etc.)
%       -- bypass seed if operating on 'registered-interleaved' dir, to allow post-hoc reconstruction of all steps (edit applyShifts functions)
%       -- save all stitched tiffs in main, with channel number and final reg step in fname
%-----------------------------------------------------------------------------------------------------------

function [ status, err_msg ] = iCorre_batch(root_dir,search_filter,params)

%% Get list of data directories
if nargin<2 || ~exist("search_filter","var")
    search_filter = '';
end
temp = dir(fullfile(root_dir,search_filter)); %Edit to specify data directories
data_dirs = {temp.name};
temp = ~(ismember(data_dirs,{'.','..'})) & ~isfile(fullfile(root_dir,data_dirs)) & strcmp({temp(:).folder}, root_dir);
data_dirs = data_dirs(temp); %remove '.', '..', subdirs, and any files from directory list
disp(['Root directory: ' root_dir]);
disp(['Matching subdirectories for "' search_filter '"...']);
disp('Directories for movement correction:');
disp(data_dirs');
clearvars temp;

%% Setup parallel pool for faster processing
if isempty(gcp('nocreate'))
    try
        parpool([4 128])
    catch err
        warning(err.message);
    end
end

%% Get directories and filenames
for i=1:numel(data_dirs)
    try

        %Get Hyperparameters (if not included as input args)
        if nargin<3
            %Load from MAT file
            %Precedence: params argument, then settings in session dir, then batch dir
            session_settings = fullfile(root_dir,data_dirs{i},'user_settings.mat');
            if exist(session_settings,'file') %Settings in session dir
                params = getUserSettings(session_settings, false);
            elseif exist(fullfile(root_dir,'user_settings.mat'),'file')
                params = getUserSettings(fullfile(root_dir,'user_settings.mat'), false);
            else %If no MAT file, use defaults and save MAT
                warning("File 'user_settings.mat' not found in root directory. Initializing file with the default settings...")
                params = getUserSettings(fullfile(root_dir,'user_settings.mat'), false);
            end
        end
        disp(['*** Hyperparameters for ' data_dirs{i} ' ***']);
        disp(params);

        % Setup Subdirectories and File Paths
        [dirs, paths] = iCorreFilePaths(root_dir, data_dirs{i}, params.source_dir);

        %If No 'raw' Directory, Create It & Move the TIF Files There
        if ~exist(dirs.raw,'dir')
            mkdir(dirs.raw);
            movefile(fullfile(dirs.main,'*.tif'), dirs.raw);
        end

        %Remove any existing MAT directory
        if exist(dirs.mat,'dir')
            if strcmp(dirs.source, dirs.raw) %If temp MAT files exist and input data are raw (unregistered)
                rmdir(dirs.mat,'s'); %Start over from scratch
            else %Move prior MAT files
                movefile(dirs.mat,fullfile(dirs.source,['mat' datestr(now,'yymmddHHMM')]));
                if exist(paths.regData,'file') %Also move registration data
                    movefile(paths.regData, fullfile(dirs.source,['reg_info' datestr(now,'yymmddHHMM') '.mat']));
                end
            end
        end
        %Make MAT directory
        create_dirs(dirs.mat);

        %Display Paths
        disp(['Data directory: ' dirs.source]);
        disp({['Path for stacks as *.mat files: ' dirs.mat];...
            ['Path for info file: ' paths.regData]});
             
        %% Load raw TIFs and convert to MAT for further processing
        disp('Converting *.TIF files to *.MAT for movement correction...');

        stackInfo = tiff2mat_parallel(paths.source, paths.mat,...
            struct(...
            'chan_number',params.ref_channel,...
            'crop_margins',params.crop_margins,...
            'read_method',params.read_method,...
            'extract_I2C',params.saveI2CData)); %Batch convert all TIF stacks to MAT and get info.
        if ~exist(paths.stackInfo,"file")
            save(paths.stackInfo,'-STRUCT','stackInfo','-v7.3');
        else
            save(paths.stackInfo,'-STRUCT','stackInfo','-append');
        end

         %Check params
        params.imageSize = [stackInfo.imageHeight, stackInfo.imageWidth];
        params = iCorreCheckParams(params); %**under devo** Currently checks grid_size against image size

        %% Correct RIGID, then NON-RIGID movement artifacts iteratively
        % Set parameters
        RMC_shift = round(0.5*params.max_shift); %Params value used for SEED (based on reference image); therefter, narrow the degrees freedom
        NRMC_shift = round(0.5*params.max_shift); %[10,10]; max dev = [8,8] for 512x512
        overlap = round(params.grid_size/4); %[32,32] for 512x512

        options.seed = NoRMCorreSetParms('d1',stackInfo.imageHeight,'d2',stackInfo.imageWidth,...
            'max_shift',params.max_shift,'shifts_method','FFT',...
            'correct_bidir',true,'bidir_us',1,... %correct_bidir appears to introduce artifacts when us_fac>1; use with caution.
            'boundary','NaN','upd_template',false,...
            'print_msg',false); %Initial rigid correct for drift
        options.RMC = NoRMCorreSetParms('d1',stackInfo.imageHeight,'d2',stackInfo.imageWidth,...
            'max_shift',RMC_shift,'shifts_method','FFT',...
            'correct_bidir',false,...  %use correct_bidir only on seed
            'boundary','NaN','upd_template',false,...
            'print_msg',false); %Rigid Correct; avg whole stack for template
        options.NRMC = NoRMCorreSetParms('d1',stackInfo.imageHeight,'d2',stackInfo.imageWidth,......
            'grid_size',params.grid_size,'overlap_pre',overlap,'overlap_post',overlap,...
            'max_shift',NRMC_shift,'max_dev',params.max_dev,...
            'correct_bidir',false,...
            'shifts_method','cubic',... %Only cubic shifts are supported if using normcorre_batch_even
            'boundary','NaN','upd_template',false,...
            'use_parallel',true,'print_msg',false);

        % Bypass SEED registration if working with pre-registered stack
        if ~strcmp(dirs.source, dirs.raw)
            params.max_reps(1) = 0;
        end

        % Generate SEED Template and Initialize MAT file
        template = getRefImg(paths.mat,stackInfo,params.nFrames_seed); %Generate initial reference image to use as template
        save(paths.regData,'params','-v7.3'); %so that later saves in the loop can use -append

        % Iterative movement correction
        options_label = fieldnames(options);
        for m = find(params.max_reps) %seed, rigid, non-rigid
            tic;
            disp(' ');
            disp([upper(options_label{m}) ' registration in progress...']);

            [template,nReps] = ...
                iCorre(paths.mat, options.(options_label{m}), options_label{m}, template,...
                params.max_err, params.max_reps(m));

            template_out.(options_label{m}) = template;
            nRepeats.(options_label{m}) = nReps;
            run_times.(options_label{m}) = toc;

            disp([options_label{m} ' correction complete. Elapsed Time: ' num2str(run_times.(options_label{m})) 's']);
            save(paths.regData,'template_out','nRepeats','run_times','-append'); %save values
        end

        %Update regInfo and save
        field_names = fieldnames(options);
        options = rmfield(options,field_names(~params.max_reps));
        save(paths.regData,'options','-append');

        % Remove stacks from saved MAT files
        removeStackData(paths.mat);

        %% Save Registered Stacks as TIFF

        %Apply shifts as needed for each channel
        applyShiftsTime = tic;
        paths = iCorreApplyShifts_batch(paths, dirs, params);
        applyShiftsDuration = toc(applyShiftsTime);
        disp(['Time spent applying shifts to output channel(s): ' num2str(applyShiftsDuration) ' s']);

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

        clearvars '-except' root_dir data_dirs file_names dirs paths params stackInfo options_label run_times status msg i m;

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


