function [R, crispness] = mvtCorrMetrics( data_dir )

%Estimated using form from original NoRMCorre paper: https://doi.org/10.1016/j.jneumeth.2017.07.031

% Paths to Data
path.raw = getTiffPaths(fullfile(data_dir,"raw"));
path.reg = getTiffPaths(fullfile(data_dir,"registered tiff"));
path.mean = fullfile(data_dir,"stackMean.tif"); 

% Saved Metadata
stackInfo = load(fullfile(data_dir,"stack_info.mat"));
regInfo = load(fullfile(data_dir,"reg_info.mat")); 

%% Calculate Frame-by-Frame Pixel-Wise Correlation with Mean Projection
meanProj = loadtiffseq(path.mean);


%% Estimate Crispness of Mean Projection
C = NaN(numel(full_path),1,'double');
for i = 1:numel(full_path)
    img = loadtiffseq(full_path{i});
    [fX,fY] = gradient(double(img)); %Gradient vector field for x,y
    mag = sqrt((fX.^2) + (fY.^2)); %Entry-wise magnitude of gradient 
    C(i) = norm(mag,"fro"); %Crispness is the Frobenius norm (same result as norm([fX(:),fY(:)],"fro"));
end

%%
function paths = getTiffPaths(directory)
files = dir(fullfile(directory,"*.tif"));
paths = string(fullfile({files.folder}',{files.name}'));