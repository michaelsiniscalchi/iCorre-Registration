%%% getCorrFrames(stack, percentile)
%
% PURPOSE: To obtain a reference image from an image stack, derived from a percentile cut of 
%           frame-wise pixel correlations.
%
% AUTHOR: MJ Siniscalchi, Princeton Neuroscience Institute, 220215
%---------------------------------------------------------------------------------------------------

function [ reference_img, idx ] = getCorrFrames(stack, percentile)

%Obtain initial reference using frames with greatest pixel correlation
[sz1,sz2,sz3] = size(stack);
framesAsColumns = reshape(stack,[sz1*sz2, sz3]); %Reshape to calculate pairwise correlations between frames
sum_R = sum(corrcoef(framesAsColumns)); %Sum of pairwise correlations
idx = sum_R > prctile(sum_R, percentile); %Take cut of most correlated frames 
reference_img = mean(stack(:,:,idx),3); %Reference image from mean of this subsample