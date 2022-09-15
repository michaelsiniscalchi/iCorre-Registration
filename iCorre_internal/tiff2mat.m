%% tiff2mat()
%
% PURPOSE: To convert TIFF files into 3D arrays stored in MAT format.
%           Returns struct 'stackInfo' which contains selected info from ScanImage
%           header as well as the extracted tag struct for writing to TIF.
%
% AUTHOR: MJ Siniscalchi, 190826
%           -220310mjs Updated using TIFF library and ScanImageTiffReader
%--------------------------------------------------------------------------

function stackInfo = tiff2mat(tif_paths, mat_paths, options)

tic; %For command window output

%Handle options
if nargin<3
    options.chan_number     = []; %For interleaved 2-color imaging; channel to convert.
    options.crop_margins    = []; %Width of margins on each side of image; scalar or [top,bottom,left,right]
    options.extract_I2C     = false; %Flag to extract I2C data from TIFF header
    options.read_method     = 'TiffLib';
end
 
for optFields = ["chan_number","crop_margins","extract_I2C"]
    if ~isfield(options,optFields)
        options.(optFields) = [];
    end
    if ~isfield(options,"read_method")
        options.read_method = 'TiffLib';
    end
end

%% Convert each TIF File and Extract Specified Header Info
descArray = cell(numel(tif_paths),1); %Initialize cell array of image descriptions
for i = 1:numel(tif_paths)
    
    %Store name of source file
    [~,filename,ext] = fileparts(tif_paths{i});
    source = [filename ext]; 

    disp(['Converting ' source '...']);
    if i==1 % Extract general parameters for whole session from first stack
        %Metadata from ScanImage Header
        [stack, description, metadata] =  loadtiffseq(tif_paths{i},options.read_method); % load raw stack (.tif)
        stackInfo = getStackInfo(stack, description{1}, metadata); %Initialize struct 'stackInfo'
        %TIFF Tags
        tags = getTiffTags(tif_paths{i}); %Tags explicitly specified in this function
    else % Load Remaining Stacks and Extract Image Descriptions         
        [stack, description] =  loadtiffseq(tif_paths{i},options.read_method); % load raw stack (.tif)
    end

    %Check for correction based on structural channel
    if options.chan_number 
            stack = stack(:,:,options.chan_number:2:end); %Convert data from specified (eg reference) channel
            description = description(1:2:end); %Remove superfluous image descriptions
    end

    %Crop images if specified
    if options.crop_margins
        stack = cropStack(stack, options.crop_margins);
        if i==1 %Overwrite tags
            [tags.ImageLength, stackInfo.imageHeight]   = deal(size(stack,1));
            [tags.ImageWidth, stackInfo.imageWidth]     = deal(size(stack,2));
            stackInfo.margins = options.crop_margins; %[top, bottom, left, right]
        end
    end

    %Populate array of image descriptions
    if options.extract_I2C
        descArray{i} = description(:);
    end

    %Store additional info
    stackInfo.nFrames(i,1) = size(stack,3); %Store number of frames
    stackInfo.rawFileName{i,1} = source; %Save original filename
    
    %Save
    save(mat_paths{i},'stack','tags','source','-v7.3');
end

%Copy tags to stackInfo structure
stackInfo.tags = tags;

%Extract I2C Data if specified
if options.extract_I2C
    %Concatenate cell arrays for each TIFF stack
    descArray = vertcat(descArray{:});
    stackInfo.I2C = getI2CData(descArray);
end

%Console display
[pathname,~,~] = fileparts(mat_paths{1});
disp(['Stacks saved as .MAT in ' pathname]);
disp(['Time needed to convert files: ' num2str(toc) ' seconds.']);