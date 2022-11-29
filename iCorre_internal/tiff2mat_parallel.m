%% tiff2mat()
%
% PURPOSE: To convert TIFF files into 3D arrays stored in MAT format.
%           Returns struct 'stackInfo' which contains selected info from ScanImage
%           header as well as the extracted tag struct for writing to TIF.
%
% AUTHOR: MJ Siniscalchi, 190826
%           -220310mjs Updated using TIFF library and ScanImageTiffReader
%           -220919mjs Temporarily removed getStackInfo() and references to
%           image metadata (only useful with ScanImageTiffReader)
%--------------------------------------------------------------------------

function stackInfo = tiff2mat_parallel(tif_paths, mat_paths, options)

tic; %For command window output

% Handle Options
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
ImageDescription = cell(numel(tif_paths),1); %Initialize cell array of image descriptions
parfor i = 1:numel(tif_paths)
    
    %Store name of source file
    [~,filename,ext] = fileparts(tif_paths{i});
    source = [filename ext]; 
    disp(['Converting [parallel] ' source '...']);
    
    % Load Stack and Extract TIFF tags
    [stack, tags, ImageDescription{i}] =  loadtiffseq(...
        tif_paths{i},options.chan_number,options.read_method); % load raw stack (.tif)
    
    %Crop images if specified
    if ~isempty(options.crop_margins)
        stack = cropStack(stack, options.crop_margins);
        tags.ImageLength  = size(stack,1); %Editing tags may be necessary after cropping
        tags.ImageWidth    = size(stack,2);
    end

    %Store additional info
    nFrames(i,1) = size(stack,3); %Store number of frames
    rawFileName(i,1) = string(source); %Save original filename
    
    %Parallel Save
    M = matfile(mat_paths{i},'Writable',true);
    M.stack = stack;
    M.tags = tags;
    M.source = source;
end

%Copy tags to stackInfo structure
%Basic image info
Stack = load(mat_paths{1},'stack','tags');
stackInfo.class = class(Stack.stack);
stackInfo.imageHeight   = Stack.tags.ImageLength; %Editing tags may be necessary after cropping
stackInfo.imageWidth    = Stack.tags.ImageWidth;
stackInfo.nFrames       = nFrames(:); %Store number of frames
stackInfo.rawFileName   = rawFileName(:); %Save original filename
stackInfo.margins       = options.crop_margins; %[top, bottom, left, right]
stackInfo.tags          = Stack.tags; %Frame-invariant tags
stackInfo.tags.ImageDescription = ImageDescription; %Frame-specific

%Extract I2C Data if specified
if options.extract_I2C
    %Concatenate cell arrays for each TIFF stack
    stackInfo.I2C = getI2CData(vertcat(ImageDescription{:}));
end

%Console display
[pathname,~,~] = fileparts(mat_paths{1});
disp(['Stacks saved as .MAT in ' pathname]);
disp(['Time needed to convert files: ' num2str(toc) ' seconds.']);

%----------------------------------------------------------------------------
% Add this back in (and edit) if ScanImageTiffReader becomes available again!
% stackInfo = getStackInfo( stack, description, metadata )
%
% Use opentif() for user-friendly structured info, or the faster
% ScanImageTiffReader class
% [header,Aout,imgInfo,~] = scanimage.util.opentif(tif_paths{i});