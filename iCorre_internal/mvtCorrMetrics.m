function [ R, crispness, meanProj ] = mvtCorrMetrics( path_raw, path_registered, reg_channel, crop_margins )

%Estimated using form from original NoRMCorre paper: https://doi.org/10.1016/j.jneumeth.2017.07.031

% Calculate mean projection for each stack
meanProj.raw = getMeanProjection(path_raw, reg_channel, crop_margins); %Split channels
meanProj.reg = getMeanProjection(path_registered, []); %Load all frames; already cropped

% Calculate Frame-by-Frame Pixel-Wise Correlation with Mean Projection
[R.raw, R.mean.raw] = getStackCorr(path_raw, meanProj.raw, reg_channel, crop_margins);
[R.reg, R.mean.reg] = getStackCorr(path_registered, meanProj.reg, []);

% Estimate Crispness of Mean Projection
fields = ["raw","reg"];
for i = 1:numel(fields)
    [fX,fY] = gradient(meanProj.(fields(i))); %Gradient vector field for x,y
    mag = sqrt((fX.^2) + (fY.^2)); %Entry-wise magnitude of gradient 
    crispness.(fields(i)) = norm(mag,"fro"); %Crispness is the Frobenius norm (same result as norm([fX(:),fY(:)],"fro"));
end

%% INTERNAL FUNCTIONS

function mean_proj = getMeanProjection( tiff_paths, channel, crop_margins )
%Take running sum and divide by nFrames
nFrames = zeros(numel(tiff_paths),1);
if ~exist("crop_margins","var")
    crop_margins = 0;
end

for i = 1:numel(tiff_paths)
    stack = cropStack(loadtiffseq(tiff_paths(i),channel), crop_margins); %Load frames from specified channel
    sum_stack(:,:,i) = sum(double(stack),3); %Take sum across frames
    nFrames(i) = size(stack,3); %Store number of frames in stack for denomenator
end
nFrames = sum(nFrames);
mean_proj = sum(sum_stack,3)/nFrames;

% --- Get framewise correlations for whole session ---
function [ R, meanR ] = getStackCorr(path_stacks, mean_proj, channel, crop_margins )
if ~exist("crop_margins","var") || isempty(crop_margins)
    crop_margins = 0;
end

parfor i = 1:numel(path_stacks) %PARFOR
    stack = cropStack(loadtiffseq(path_stacks(i),channel), crop_margins);
    R{i} = getFrameCorr(double(stack), mean_proj);
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