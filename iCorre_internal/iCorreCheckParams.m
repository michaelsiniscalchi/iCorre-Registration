% PURPOSE: TO check for valid hyperparameters in advance
% AUTHOR: MJ Siniscalchi, 220325

function params = iCorreCheckParams(params)

%Image parameters
margins = params.crop_margins;
gridSize = params.grid_size;
imageSize = params.imageSize; %Adjust for any cropping

if any(margins) && ~ismember(numel(margins),[1,3,4]) %Only vectors of length 1, 3, or 4 allowed
    %Check crop margins
    error('params.crop_margins must be either scalar, or a 1-by-3 or 1-by-4 numeric vector. See cropStack.m for details.')
elseif isfield(params,'imageSize') && any(mod(params.imageSize,gridSize))
    %If image size is not divisible by grid size, adjust grid size and warn
    for i = 1:numel(gridSize)
        N = 1:sqrt(imageSize(i)); %Candidate unsigned factors of number of rows/columns in image
        evenGrids = imageSize(i)./N(rem(imageSize(i),N)==0); %Grid sizes that are divisors of the (cropped) image size
        idx = abs(evenGrids-gridSize(i))==min(abs(evenGrids-gridSize(i))); %Get nearest value
        params.grid_size(i) = evenGrids(idx);
    end
    outStr = ['Image size must be evenly divisible by grid size after cropping. Adjusting grid size to nearest divisors: [' num2str(params.grid_size) '].'];
    warning(outStr);
end