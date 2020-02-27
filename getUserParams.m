%%% getUserParams()
%
% PURPOSE: To get user inputs defining the hyperparameters for image registration in iCorre 
% AUTHOR: MJ Siniscalchi 200226
%
%---------------------------------------------------------------------------------------------------

function params = getUserParams()

%% SET DEFAULTS AND EXTRACT SAVED SETTINGS

settings = [...
    "ScanImage Version",                                    "scim_ver",         "5";...
    "Batch Data Directory",                                 "root_dir",         string(pwd);...
    "Search Filter (optional)",                             "search_filter",    "";...
    
    "Number of Seed Frames",                                "nFrames_seed",     "5000";...
    
    "Seed: Max. Number of Repeats",                         "maxRepSeed",       "1";...
    "Rigid: Max. Number of Repeats",                        "maxRepRMC",        "1";...
    "Non-Rigid: Max. Number of Repeats",                    "maxRepNRMC",       "1";...
        
    "Rigid: Max. Shift (pixels):",                          "max_shift",        "16";...
    "Non-Rigid: Max. Deviation from Rigid Shift (pixels)",  "max_dev",          "16";...
    "Non-Rigid: Patch Width",                               "grid_size",        "16";...
        
    "Error Tolerance (pixels)",                             "max_err",          "1";...
    "Reference Channel (0 for 1-color imaging)",            "ref_channel",      "0";...
    "Follower Channel (0 for 1-color imaging)",             "reg_channel",      "0";...
    "Save Concatenated Copy of Corrected Stacks? (T/F)",    "do_stitch",        "T";...
    "Downsample Factor for Concatenated Stack",             "bin_width",        "20";...
    "Delete MAT files at Completion? (T/F)",                "delete_mat",       "T";...
    ];

if exist('user_params.mat','file')
    s = load('user_params');
    settings = s.settings;
end

opts = struct('Resize','on','WindowStyle','modal','Interpreter','none');
settings(:,3) = string(inputdlg(settings(:,1),'*** iCORRE: Set Image Registration Parameters ***',1,settings(:,3),opts));

%% Save settings
save(fullfile(pwd,'user_params'),'settings');

%% Convert to correct MATLAB classes

% String or Numeric
for i = 1:size(settings,1)
    switch settings{i,2}
        case {"root_dir", "search_filter",""} %Strings
            params.(settings{i,2}) = settings{i,3};
        case {"scim_ver","nFrames_seed","max_err","ref_channel","reg_channel","bin_width"} %Numeric
            params.(settings{i,2}) = str2double(settings{i,3});
        case {"grid_size","max_shift","max_dev"} %Numeric
            params.(settings{i,2}) = repmat(str2double(settings{i,3}),1,2);
        case "maxRepSeed"
            params.maxReps = str2double(settings(ismember(settings(:,2),["maxRepSeed","maxRepRMC","maxRepNRMC"]),3))';
    end
    switch settings{i,3} %Logical
        case "T"
            params.(settings{i,2}) = true;
        case "F"
            params.(settings{i,2}) = false;
    end
end