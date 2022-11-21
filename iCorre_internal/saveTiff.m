%%saveTiff( img_stack, tags, save_path )
%
%PURPOSE: Saves imaging stacks from MATLAB arrays to TIF.
%AUTHOR: MJ Siniscalchi, 180507
%LAST EDIT: 220310
%
%INPUT ARGS:
%   'img_stack': Y x X x Time numeric array representing a stack of image frames
%   'tags': A structure containing the tags (e.g., ImageHeight & ImageWidth)
%       to be attached to all frames of the TIF file. If tiff2mat.m was used
%       to generate MATLAB array, then struct 'stackInfo' will contain all necessary tags.
%   'save_path': (char) full save path with file name.
%
%EDITS:
%   180718mjs   If imfinfo() was used to get img_info, returns 'Height' and 'Width'
%               instead of valid Tiff tags; added translation of image info into valid tags.
%
%   220310mjs   Simplified to take TIFF tags instead of translating from imfinfo.m output.
%                   Tiff library works much better and faster...
%---------------------------------------------------------------------------------------------------

function saveTiff( img_stack, tags, save_path )

%Save stack as TIF
disp(join(['Saving stack as ' save_path '...']));

%Extract and store frame-specific tags
if isfield(tags,'ImageDescription') 
    if numel(tags.ImageDescription)==size(img_stack,3)
        ImageDescription = tags.ImageDescription;
    end
    tags = rmfield(tags,'ImageDescription');
end

%Write TIFF
t = Tiff(save_path,'w'); %open/create tif for writing
for i = 1:size(img_stack,3) %create write dir, tag, and write subsequent frames
    if i>1
        t.writeDirectory();
    end
    t.setTag(tags); %Frame-invariant tags
    if exist('ImageDescription','var')
        t.setTag('ImageDescription',ImageDescription{i});
    end
    t.write(img_stack(:,:,i));
end
t.close();