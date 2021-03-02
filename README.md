# iCorre-Registration
Recursive motion correction for 2-photon imaging data, using one or two color channels. 
Based on NoRMCorre by flatironinstitute (https://github.com/flatironinstitute/NoRMCorre).

User settings can be set and saved using the GUI, 'start_iCorre.m' in the main code directory.

------------------------------------------------------------------------------------------------------

SETTING                                                           VARIABLE NAME       DEFAULT VALUE

Batch Directory (optional),                                       "root_dir",         ""
Search Filter (optional),                                         "search_filter",    ""
Save Settings As...,                                              "path_settings",    path_settings
    
ScanImage Version,                                                "scim_ver",         "5"
    
Number of Frames to Average for Reference Image,                  "nFrames_seed",     "1000"
   
Rigid Correction: Max. Number of Repeats,                         "maxRepRMC",        "1"
Non-Rigid Correction: Max. Number of Repeats,                     "maxRepNRMC",       "1"
        
Rigid Correction: Max. Shift (pixels),                            "max_shift",        "10"
Non-Rigid Correction: Max. Deviation from Rigid Shift (pixels),   "max_dev",          "5"
Non-Rigid Correction: Patch Width,                                "grid_size",        "16"
        
Error Tolerance (pixels)",                                        "max_err",         "1"
Reference Channel (0 for 1-color imaging),                        "ref_channel",      "0"
Follower Channel (0 for 1-color imaging),                         "reg_channel",      "0"
Save Concatenated Copy of Corrected Stacks? (T/F),                "do_stitch",        "T"
Downsample Factor for Concatenated Stack,                         "bin_width",        "20"
Delete MAT files at Completion? (T/F),                            "delete_mat",       "F"
