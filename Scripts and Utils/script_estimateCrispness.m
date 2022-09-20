%Estimated using form from original NoRMCorre paper: https://doi.org/10.1016/j.jneumeth.2017.07.031

data_dir = 'C:\Data\2-Photon Imaging\Sessions for Batch Processing\220311 M413 T7_crop\';
full_path = {...
    fullfile(data_dir,'stitched_mCherry','stackMean.tif');...
    fullfile(data_dir,'registered_ref_channel','stackMean.tif');...
    fullfile(data_dir,'stitched_GCaMP','stackMean.tif');...
    fullfile(data_dir,'stackMean.tif')...
    };

C = NaN(numel(full_path),1,'double');
for i=1:numel(full_path)
    img = loadtiffseq(full_path{i});
    [fX,fY] = gradient(double(img)); %Gradient vector field for x,y
    mag = sqrt((fX.^2) + (fY.^2)); %Entry-wise magnitude of gradient 
    C(i) = norm(mag,"fro"); %Crispness is the Frobenius norm (same result as norm([fX(:),fY(:)],"fro"));
end
