function iCorreBinnedAvg_posthoc( data_dir )

[ root_path, data_dir ] = fileparts(data_dir);
[dirs, paths] = iCorreFilePaths(root_path, data_dir, []); %'source' dir not needed
stackInfo = load(paths.stackInfo);
S = load(paths.regData,'params');

disp(['Downsampling session ' data_dir '...']);
disp(['Main data directory: ' dirs.main]);
disp(['Registered data directory: ' dirs.registered]);
disp(['Source for downsample: ' fileparts(paths.registered{1})]);
binnedAvg_batch(paths.registered, dirs.main, stackInfo, S.params );

% for i = 1:numel(paths.registered)
%     binnedAvg_batch(paths.registered{i}, dirs.main, stackInfo, S.params );
% end