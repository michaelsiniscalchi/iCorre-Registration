%%% getUserParams()
%
% PURPOSE: To get user inputs defining the hyperparameters for image registration in iCorre 
% AUTHOR: MJ Siniscalchi 200226
%
%---------------------------------------------------------------------------------------------------

function [ params, root_dir, search_filter ] = getUserSettings( path_settings, inputBox_TF )

%% CHECK FOR SAVED SETTINGS

%If a path is specified, use those settings
if nargin < 1
    path_settings = string(fullfile(pwd,'user_settings.mat'));
end
if nargin < 2
    inputBox_TF = true; %Bring up input box for user input
end

%% FIXED PARAMETERS
maxRepSeed = 1; %Number of repetitions for ref. image (seed) fixed at 1


%% SET DEFAULTS AND EXTRACT SAVED SETTINGS

% These default settings have worked well for most data acquired at 30 Hz/512x512 pixels
%   -with the exception of cropping, which usually helps but should be decided for each case
settings = [...
    
    "Batch Directory (optional)",                                       "root_dir",         "";...
    "Search Filter (optional)",                                         "search_filter",    "";...
    "Save Settings As...",                                              "path_settings",    path_settings;...
       
    "Directory Name for Source Data",                                   "source_dir",       "raw";...

    "Number of Frames to Average for Reference Image",                  "nFrames_seed",     "5000";...

    "Crop Margins (pixels: [T,B,L,R] or [T,L,width] or scalar)",        "crop_margins",     "[]";...
   
    "Rigid Correction: Max. Number of Repeats",                         "maxRepRMC",        "2";...
    "Rigid Correction: Max. Shift (pixels)",                            "max_shift",        "20";...
       
    "Non-Rigid Correction: Max. Number of Repeats",                     "maxRepNRMC",       "3";...
    "Non-Rigid Correction: Patch Width",                                "grid_size",        "128";...
    "Non-Rigid Correction: Max. Deviation from Rigid Shift (pixels)",   "max_dev",          "8";...
         
    "Error Tolerance (pixels)",                                         "max_err",          "5";...

    "Reference Channel (0 for 1-color imaging)",                        "ref_channel",      "2";...
    "Follower Channel (0 for 1-color imaging)",                         "reg_channel",      "1";...
    "Save Reference Channel? (T/F)"                                     "save_ref",         "T";...
    "Preserve Channel Order from Source Data? (T/F)"                    "save_interleaved", "F";...

    "Extract I2C Data from TIFF Header?"                                "saveI2CData",      "T";...

    "Save Concatenated TIFF of Corrected Stacks? (T/F)",                "do_stitch",        "T";...
    "Downsample Factor for Concatenated Stack",                         "bin_width",        "30";...
   
    ];

%% Get user input and save settings
if exist(path_settings,'file')
    s = load(path_settings);
    settings = s.settings;
elseif ~inputBox_TF
    warning(['No settings found at ' path_settings]);
    disp('Applying default settings.');
end

if inputBox_TF
    opts = struct('Resize','on','WindowStyle','modal','Interpreter','none');
    settings(strcmp(settings(:,2),"path_settings"),3) = path_settings;
    settings(:,3) = string(inputdlg(settings(:,1),...
        '*** iCORRE: Set Image Registration Parameters ***',1,settings(:,3),opts));
    path_settings = settings(strcmp(settings(:,2),"path_settings"),3);
end

%% Convert to correct MATLAB classes

% String or Numeric
for i = 1:size(settings,1)
    switch settings{i,2}
        case {"root_dir", "source_dir"} %Strings
            params.(settings{i,2}) = settings{i,3};
        case "search_filter" 
            params.(settings{i,2}) = settings{i,3};
            if ~isempty(settings{i,3}) %Default is all directories
                params.(settings{i,2}) = strjoin(["*",settings{i,3},"*"],'');
            end
        case {"nFrames_seed","max_err","ref_channel","reg_channel","bin_width"} %Numeric
             params.(settings{i,2}) = str2double(settings{i,3});
        case "crop_margins"
            params.(settings{i,2}) = str2num(settings{i,3}); %#ok<ST2NM> %Numeric, can be list
            if numel(params.crop_margins)==1
                params.crop_margins = repmat(params.crop_margins,1,4);
            end
        case {"grid_size","max_shift","max_dev"} %Numeric
            params.(settings{i,2}) = repmat(str2double(settings{i,3}),1,2);
        case "maxRepRMC"
            maxReps = str2double(settings(ismember(settings(:,2),["maxRepRMC","maxRepNRMC"]),3))';
            params.max_reps = [maxRepSeed, maxReps]; %Number of repetitions for ref. image (seed) fixed at 1
    end

    switch settings{i,3} %Logical
        case "T"
            params.(settings{i,2}) = true;
        case "F"
            params.(settings{i,2}) = false;
    end
end

%Additional params not included in input()
params.read_method = 'TiffLib'; %'imread','TiffLib','scim'

%Save params as struct
if inputBox_TF %If interactive
    save(path_settings,'settings'); %String array
    save(path_settings,'-struct','params','-append'); %Structure
end

%Additional Outputs for iCorre_batch()
root_dir        = params.root_dir;
search_filter   = params.search_filter;