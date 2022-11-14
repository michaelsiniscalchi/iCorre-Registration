root_dir = 'Y:\Michael\_testing';
search_filter = '';
params = load(fullfile(root_dir,'user_settings.mat'));
meanProject_batch( root_dir, search_filter, params.ref_channel );