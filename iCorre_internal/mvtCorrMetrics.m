function [ R, crispness, meanProj ] = mvtCorrMetrics( data_dir, reg_channel )

%Estimated using form from original NoRMCorre paper: https://doi.org/10.1016/j.jneumeth.2017.07.031

% Paths to Data
path.raw = getTiffPaths(fullfile(data_dir,"raw"));
path.reg = getTiffPaths(fullfile(data_dir,"registered tiff"));

% Calculate mean projection for each stack
meanProj.raw = getMeanProjection(path.raw, reg_channel);
meanProj.reg = getMeanProjection(path.reg);

% Calculate Frame-by-Frame Pixel-Wise Correlation with Mean Projection
[R.raw, R.mean.raw] = getStackCorr(path.raw, meanProj.raw, reg_channel);
[R.reg, R.mean.reg] = getStackCorr(path.reg, meanProj.reg);

% Estimate Crispness of Mean Projection
fields = ["raw","reg"];
for i = 1:numel(fields)
    [fX,fY] = gradient(meanProj.(fields(i))); %Gradient vector field for x,y
    mag = sqrt((fX.^2) + (fY.^2)); %Entry-wise magnitude of gradient 
    crispness.(fields(i)) = norm(mag,"fro"); %Crispness is the Frobenius norm (same result as norm([fX(:),fY(:)],"fro"));
end

%% INTERNAL FUNCTIONS
function paths = getTiffPaths(directory)
files = dir(fullfile(directory,"*.tif"));
paths = string(fullfile({files.folder}',{files.name}'));

function mean_proj = getMeanProjection( tiff_paths, channel )
%Take running sum and divide by nFrames
if ~exist('channel','var')
    channel = [];
end
nFrames = zeros(numel(tiff_paths),1);
parfor i = 1:numel(tiff_paths)
    stack = double(loadtiffseq(tiff_paths(i), channel)); %Load frames from specified channel
    sum_stack(:,:,i) = sum(stack,3); %Take sum across frames
    nFrames(i) = size(stack,3); %Store number of frames in stack for denomenator
end
nFrames = sum(nFrames);
mean_proj = sum(sum_stack,3)/nFrames;

% --- Get framewise correlations for whole session ---
function [ R, meanR ] = getStackCorr(path_stacks, mean_proj, channel)
if ~exist('channel','var')
    channel = [];
end
parfor i = 1:numel(path_stacks) %PARFOR
    stack = double(loadtiffseq(path_stacks(i), channel));
    R{i} = getFrameCorr(stack, mean_proj);
end
R = [R{:}]'; %Aggregate framewise correlations from each substack
meanR = mean(R);

% --- Get framewise correlations from each substack ---
function R = getFrameCorr(stack, mean_proj)
R = zeros(1,size(stack,3)); %Initialize
for i = 1:size(stack,3)
    R_mat = corrcoef(stack(:,:,i), mean_proj);
    R(i) = R_mat(2); %First off-diagonal coefficient
end