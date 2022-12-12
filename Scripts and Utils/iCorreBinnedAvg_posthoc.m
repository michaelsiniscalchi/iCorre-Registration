function iCorreBinnedAvg_posthoc( data_dir )

[ root_path, data_dir ] = fileparts(data_dir);
[dirs, paths] = iCorreFilePaths(root_path, data_dir, []); %'source' dir not needed
stackInfo = load(paths.stackInfo);
S = load(paths.regData,'params');

for i = 1:numel(paths.registered)
    binnedAvg_batch(paths.registered{i}, dirs.main, stackInfo, S.params );
end