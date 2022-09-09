

% options.write_to_tiff
% options.save_path

full_path = 'C:\Data\2-Photon Imaging\Sessions for Batch Processing\220311 M413 T7_dft\raw\220311 M413 T6_00001_00001.tif';
[stack, descriptions, metadata] = loadtiffseq(full_path);
stackInfo = getStackInfo(stack, metadata);

