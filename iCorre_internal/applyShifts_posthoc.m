% Save Registered Stacks as TIFF
clearvars;

%% Load Registration Data
root_dir = 'C:\Data\2-Photon Imaging';
data_dir = uigetdir(root_dir);
[dirs, paths, stackInfo, params] = getRegData(data_dir);

tic;

%% Apply registration to second channel if needed
if params.ref_channel~=params.reg_channel
    paths.save = applyShifts_batch(paths,dirs.save,stackInfo,params.reg_channel); %Apply shifts and save .TIF files
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
