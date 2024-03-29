clearvars;
data_dir = 'C:\Data\TaskLearning_VTA\data\220309 M413 T6_test';
stackInfo = load(fullfile(data_dir,"stack_info.mat"));
regInfo = load(fullfile(data_dir,"reg_info.mat"));

root_dir = 'C:\Data\TaskLearning_VTA\data';
search_filter = '*220309 M413 T6_test*';
params = load(fullfile(root_dir,'user_settings.mat'));
[ status, err_msg ] = iCorre_batch(root_dir,search_filter,params);

%%
clearvars;
root_dir = "W:\iCorre-test\Data\";
dirs.data = ["220309 M413 T6 pseudorandom"];
dirs.raw = string(fullfile(root_dir,dirs.data,"raw"));
filename = [...
    "220309 M413 T6_00001_00001.tif";...
    "220309 M413 T6_00001_00246.tif"];

for i = 1:numel(filename)
    dirs.mat(i) = fullfile(root_dir,dirs.data,'mat');
    paths.raw(i) = fullfile(dirs.raw,filename(i));
    paths.mat(i) = fullfile(dirs.mat(i),[filename{i}(1:end-4) '.mat']); %MAT file (working file for read/write across iterations)
end

params = load(fullfile(root_dir,'user_settings.mat'));
options = struct(...
            'chan_number',params.ref_channel,...
            'crop_margins',params.crop_margins,...
            'read_method',params.read_method,...
            'extract_I2C',params.saveI2CData); %Batch convert all TIF stacks to MAT and get info.
stackInfo = tiff2mat(paths.raw, paths.mat, options);