% Utility to save storage size by removing pixel data ('stack') from MAT files, 
%   while preserving registration metadata

function removeStackData(mat_paths)     

parfor i = 1:numel(mat_paths)
    S = load(mat_paths{i}); %load MAT file containing pixel data and metadata
    S = rmfield(S, 'stack'); %remove pixel data while preserving transformations
    save_mat(mat_paths{i}, S); %overwrite existing MAT file
end

function save_mat(path, struct_data)
save(path, '-STRUCT', 'struct_data');
