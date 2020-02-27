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
%-----------------------------------------------------------------------------------------------------------

function [ status, err_msg ] = iCorre_batch(root_dir,search_filter,params)
%% Set Parameters (if not included as input args)
if nargin<3
    params.max_reps = [1,1,1]; %maximum number of repeats; [seed, rigid, non-rigid]
    params.max_err = 1; %threshold abs(dx)+abs(dy) per frame
    params.nFrames_seed = 1000; %nFrames to AVG for for initial ref image
    if nargin<2
        search_filter = '';
    end
end

%% Get list of data directories
temp = dir(fullfile(root_dir,search_filter)); %Edit to specify data directories
data_dirs = {temp.name};
temp = ~(strcmp(data_dirs,'.') | strcmp(data_dirs,'..'));
data_dirs = data_dirs(temp); %remove '.' and '..' from directory list
disp('Directories for movement correction:');
disp(data_dirs');

%% Setup parallel pool for faster processing
if isempty(gcp('nocreate'))
    try
        parpool
    catch err
        warning(err.message);
    end
end

%% Get directories and filenames
for i=1:numel(data_dirs)
    try
        dirs.main = fullfile(root_dir,data_dirs{i});
        dirs.raw = fullfile(root_dir,data_dirs{i},'raw');
        dirs.mat = fullfile(root_dir,data_dirs{i},'MAT');
        dirs.save = fullfile(root_dir,data_dirs{i},'registered'); %to save registered stacks as TIFF
        if params.split_channels.ref_channel~=params.split_channels.reg_channel && params.do_stitch %If two-color co-registration
            dirs.save_ref = fullfile(root_dir,data_dirs{i},'reg_master'); %Save dir for registered master channel
        end
        
        field_names = fieldnames(dirs);
        for j=1:numel(field_names)
            if ~exist(dirs.(field_names{j}),'dir')
                mkdir(dirs.(field_names{j}));
            end
        end
        
        temp = dir(fullfile(dirs.raw,'*.tif'));
        for j=1:numel(temp)
            file_names{j} = temp(j).name;
            paths.raw{j} = fullfile(dirs.raw,file_names{j});
            paths.mat{j} = fullfile(dirs.mat,[file_names{j}(1:end-4) '.mat']); %for .mat file
        end
        paths.regData = fullfile(root_dir,data_dirs{i},'reg_info.mat'); %Matfile containing registration data
        paths.stackInfo = fullfile(root_dir,data_dirs{i},'stack_info.mat'); %Matfile containing image header info and tag struct for writing to TIF
        
        disp(['Data directory: ' dirs.raw]);
        disp({['Path for stacks as *.mat files: ' dirs.mat];...
            ['Path for info file: ' paths.regData]});
        
        clearvars temp;
        
        %% Load raw TIFs and convert to MAT for further processing
        disp('Converting *.TIF files to *.MAT for movement correction...');
        stackInfo = get_stackInfo_iCorre(paths.raw, params); %Extract header info from image stack (written by ScanImage)
        stackInfo.tags = tiff2mat(paths.raw, paths.mat, params.split_channels.ref_channel); %Batch convert all TIF stacks to MAT and get info.
        save(paths.stackInfo,'-STRUCT','stackInfo','-v7.3');
        
        %% Correct RIGID, then NON-RIGID movement artifacts iteratively
        % Set parameters
        options.seed = NoRMCorreSetParms('d1',stackInfo.imageHeight,'d2',stackInfo.imageWidth,'max_shift',[15,15],...
            'boundary','zero','upd_template',false,'use_parallel',true,'output_type','mat'); %Initial rigid correct for drift
        options.RMC = NoRMCorreSetParms('d1',stackInfo.imageHeight,'d2',stackInfo.imageWidth,'max_shift',[10,10],...
            'boundary','zero','upd_template',false,'use_parallel',true,'output_type','mat'); %Rigid Correct; avg whole stack for template
        options.NRMC = NoRMCorreSetParms('d1',stackInfo.imageHeight,'d2',stackInfo.imageWidth,'boundary','zero',...
            'grid_size',[64,64],'overlap_pre',[16,16],'overlap_post',[16,16],...
            'max_shift',[10,10,0],'max_dev',[5,5,0],'upd_template',false,'use_parallel',true,...
            'output_type','mat','correct_bidir',false); %Non-rigid Correct; {'correct_bidir',true} threw error in iCorre.m on some data sets.
        
        % Initialize .mat file
        save(paths.regData,'params','-v7.3'); %so that later saves in the loop can use -append
        
        % Iterative movement correction
        template = getRefImg(paths.mat,stackInfo,params.nFrames_seed); %Generate initial reference image to use as template
        
        options_label = fieldnames(options);
        for m = find(params.max_reps) %seed, rigid, non-rigid
            tic;
            disp(' ');
            disp([upper(options_label{m}) ' registration in progress...']);
            
            [template,nReps,err_mat.(options_label{m})] = ...
                iCorre(paths.mat,options.(options_label{m}),options_label{m},template,...
                params.max_err,params.max_reps(m));
            
            template_out.(options_label{m}) = template;
            nRepeats.(options_label{m}) = nReps;
            run_times.(options_label{m}) = toc;
            
            disp([options_label{m} ' correction complete. Elapsed Time: ' num2str(run_times.(options_label{m})) 's']);
            save(paths.regData,'template_out','err_mat','nRepeats','run_times','-append'); %save values
            
        end
        
        %Update regInfo and save
        field_names = fieldnames(options);
        options = rmfield(options,field_names(~params.max_reps));
        save(paths.regData,'options','-append');
        
        %% Save registered stacks as TIFF
        tic;
        
        %Apply registration to second channel if needed
        if params.split_channels.ref_channel~=params.split_channels.reg_channel
            paths.save = applyShifts_batch(paths,dirs.save,stackInfo,params.split_channels.reg_channel); %Apply shifts and save .TIF files
            if params.do_stitch
                disp('Getting global downsampled stack (binned avg.) and max projection from reference channel...');
                binnedAvg_batch(paths.mat,dirs.save_ref,stackInfo,params.bin_width); %Save binned avg and projection to ref-channel dir
                if params.delete_mat
                        rmdir(dirs.mat,'s'); %DELETE .MAT dir...
                end
                disp('Getting global downsampled stack (binned avg.) and max projection of co-registered frames...');
                binnedAvg_batch(paths.save,dirs.main,stackInfo,params.bin_width); %Save binned avg and projection to main data dir
            end
            
        else
            %Save registered stacks as .TIF
            for k = 1:numel(file_names)
                S = load(paths.mat{k},'stack'); %load into struct to avoid eval(stack_names{k})
                saveTiff(S.stack,stackInfo.tags,fullfile(dirs.save,[options_label{m} '_' file_names{k}])); %saveTiff(stack,img_info,save_path))
            end
            if params.do_stitch %Generate global and summary stacks for quality control
                disp('Getting global downsampled stack (binned avg.) and max projection of registered frames...');
                binnedAvg_batch(paths.mat,dirs.main,stackInfo,params.bin_width); %Save binned avg and projection to main data dir
            end
            if params.delete_mat
                rmdir(dirs.mat,'s'); %DELETE .MAT dir...
            end
        end
        
        clearvars S;
        run_times.saveTif = toc;
        save(paths.regData,'run_times','-append'); %save parameters
        
        clearvars '-except' root_dir data_dirs file_names dirs paths params stackInfo options_label run_times status msg i m;
        
        
    catch err
        disp(err);
        disp([{err.stack.file}' {err.stack.line}']);
    end %end try
    
    if ~exist('err','var')
        status(i) = true;
        err_msg{i} = [];
    else
        status(i) = false;
        err_msg{i} = err;
        save(paths.regData,'err_msg','-append'); %save error msg
    end
    
    clearvars '-except' root_dir data_dirs params i status err_msg;
end %end <<for i=1:numel(data_dirs)>>

