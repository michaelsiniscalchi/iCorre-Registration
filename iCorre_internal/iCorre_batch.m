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
%-----------------------------------------------------------------------------------------------------------

function [ status, err_msg ] = iCorre_batch(root_dir,search_filter,params)

%% Get list of data directories
if nargin<2 || ~exist("search_filter","var")
    search_filter = '';
end
files = dir(fullfile(root_dir,search_filter)); %Edit to specify data directories
data_dirs = {files.name};
files = ~(strcmp(data_dirs,'.') | strcmp(data_dirs,'..') | isfile(data_dirs));
data_dirs = data_dirs(files); %remove '.', '..', and any files from directory list
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

%% Get directories and filenames
for i=1:numel(data_dirs)
    try

        %Get Hyperparameters (if not included as input args)
        if nargin<3
            %Load from MAT file
            %Precedence: params argument, then settings in session dir, then batch dir 
            session_settings = fullfile(root_dir,data_dirs{i},'user_settings.mat');
            if exist(session_settings,'file')
                [~, ~, params] = getUserSettings(session_settings, false);
            elseif exist(fullfile(root_dir,'user_settings.mat'),'file')
                [~, ~, params] = getUserSettings(fullfile(root_dir,'user_settings.mat'), false);
            else %If no MAT file, use defaults and save MAT
                warning("File 'user_settings.mat' not found in root directory. Initializing file with the default settings...")
                [~, ~, params] = getUserSettings(fullfile(root_dir,'user_settings.mat'), false);
            end
        end
        disp(['*** Hyperparameters for ' data_dirs{i} ' ***']);
        disp(params);
        
        % Define & Create Subdirectories
        dirs.main = fullfile(root_dir,data_dirs{i});
        dirs.raw = fullfile(root_dir,data_dirs{i},'raw');
        dirs.mat = fullfile(root_dir,data_dirs{i},'mat');
        dirs.save_mat = fullfile(root_dir,data_dirs{i},'registered mat');
        dirs.save_tiff = fullfile(root_dir,data_dirs{i},'registered tiff'); %to save registered stacks as TIFF
        if params.ref_channel && params.reg_channel && params.do_stitch %If two-color co-registration
            dirs.save_ref = fullfile(root_dir,data_dirs{i},'registered_ref_channel'); %Save dir for registered reference channel (for two-color co-registration)
        end
        
        % If No 'raw' Directory, Create It & Move the TIF Files There
        if ~exist(dirs.raw,'dir')
            mkdir(dirs.raw);
            movefile(fullfile(dirs.main,'*.tif'),dirs.raw);
        end

        % Delete any existing MAT directory
        if exist(dirs.mat,'dir')
            rmdir(dirs.mat,'s'); %MAT files for saving registration-in-progress
        end

        % Create remaining directories
        field_names = fieldnames(dirs);
        for j=1:numel(field_names)
            create_dirs(dirs.(field_names{j}));
        end
        
        % Define All Filepaths Based on Data Filename
        files = dir(fullfile(dirs.raw,'*.tif'));
        for j=1:numel(files)
            paths.raw{j} = fullfile(dirs.raw,files(j).name); %Raw TIFFs for registration
            paths.mat{j} = fullfile(dirs.mat,[files(j).name(1:end-4) '.mat']); %MAT file (working file for read/write across iterations)
        end
        
        % Additional Paths for Metadata
        paths.regData = fullfile(root_dir,data_dirs{i},'reg_info.mat'); %Matfile containing registration data
        paths.stackInfo = fullfile(root_dir,data_dirs{i},'stack_info.mat'); %Matfile containing image header info and tag struct for writing to TIF
        
        %Display Paths
        disp(['Data directory: ' dirs.raw]);
        disp({['Path for stacks as *.mat files: ' dirs.mat];...
            ['Path for info file: ' paths.regData]});
        
        clearvars temp;
        
        %% Load raw TIFs and convert to MAT for further processing
        disp('Converting *.TIF files to *.MAT for movement correction...');

        stackInfo = tiff2mat(paths.raw, paths.mat,...
            struct(...
            'chan_number',params.ref_channel,...
            'crop_margins',params.crop_margins,...
            'read_method',params.read_method,...
            'extract_I2C',params.saveI2CData)); %Batch convert all TIF stacks to MAT and get info.

        save(paths.stackInfo,'-STRUCT','stackInfo','-v7.3');
        
        %% Correct RIGID, then NON-RIGID movement artifacts iteratively
        % Set parameters
        RMC_shift = round(0.5*params.max_shift); %Params value used for SEED (based on reference image); therefter, narrow the degrees freedom
        NRMC_shift = round(0.5*params.max_shift); %[10,10,0]; max dev = [5,5,0] for 256x256
        overlap = round(params.grid_size/4); %[16,16] for 256x256
        
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

        %--- Notes on NoRMCorreSetParms ---
        %'use_windowing' not supported when providing a template image.
        %----------------------------------
        
        %Check params
        params.imageSize = [stackInfo.imageHeight, stackInfo.imageWidth];
        params = iCorreCheckParams(params);

        % Initialize .mat file
        save(paths.regData,'params','-v7.3'); %so that later saves in the loop can use -append
        
        % Iterative movement correction
        template = getRefImg(paths.mat,stackInfo,params.nFrames_seed); %Generate initial reference image to use as template
        
        options_label = fieldnames(options);
        for m = find(params.max_reps) %seed, rigid, non-rigid
            tic;
            disp(' ');
            disp([upper(options_label{m}) ' registration in progress...']);
            
            
            [template,nReps] = ...
                iCorre(paths.mat,options.(options_label{m}),options_label{m},template,...
                params.max_err,params.max_reps(m)); 
            
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
        
        %% Save registered stacks as TIFF
        tic;
        
        %Apply registration to second channel if needed
        params.fileType_save = ["tiff","mat"]; %***for testing; later, add to params***
        if params.ref_channel && params.reg_channel %set to 0 for 1-channel imaging
            paths = applyShifts_batch(paths,dirs,stackInfo,params.reg_channel,params); %Apply shifts and save .TIF files
            if params.do_stitch
                disp('Getting global downsampled stack (binned avg.) and max projection from registered reference channel...');
                binnedAvg_batch(paths.mat,dirs.save_ref,stackInfo,params.bin_width); %Save binned avg and projection to ref-channel dir
                disp('Getting global downsampled stack (binned avg.) and max projection of co-registered frames...');
                binnedAvg_batch(paths.save_tiff,dirs.main,stackInfo,params.bin_width); %Save binned avg and projection to main data dir
            end        
        else
            %Save registered stacks as .TIF
            paths  = applyShifts_batch(paths,dirs,stackInfo,[],params); %Apply shifts and save .TIF files
            if params.do_stitch %Generate global and summary stacks for quality control
                disp('Getting global downsampled stack (binned avg.) and max projection of registered frames...');
                binnedAvg_batch(paths.save_tiff,dirs.main,stackInfo,params.bin_width); %Save binned avg and projection to main data dir
            end
        end
        
        run_times.saveTif = toc;
        save(paths.regData,'run_times','-append'); %save parameters
        
        %Remove temporary MAT files
        if params.delete_mat
            rmdir(dirs.mat,'s'); %DELETE .MAT dir...
        end
        
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


