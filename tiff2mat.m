function stackInfo = tiff2mat(raw_paths, mat_paths, chan_number)

if nargin<3
   chan_number=[]; %For interleaved 2-color imaging; channel to convert.
end

tic;
w = warning; %get warning state
warning('off','all'); %TROUBLESHOOT invalid ImageDescription tag from ScanImage

img_info = imfinfo(raw_paths{1}); %Copy info from first raw TIF
img_info = img_info(1);
fields_info = {'Height',      'Width',     'BitsPerSample','SamplesPerPixel'};
fields_tiff = {'ImageLength', 'ImageWidth','BitsPerSample','SamplesPerPixel'};
for i=1:numel(fields_info)
    stackInfo.(fields_tiff{i}) = img_info.(fields_info{i}); %Assign selected fields to stackInfo
end
stackInfo.Photometric = Tiff.Photometric.MinIsBlack;
stackInfo.PlanarConfiguration = Tiff.PlanarConfiguration.Chunky;
stackInfo.Software = 'MATLAB';

for i=1:numel(raw_paths)
    
    [path,filename,ext] = fileparts(raw_paths{i});
    disp(['Converting ' [filename,ext] '...']);

    stack = loadtiffseq(path,[filename ext]); % load raw stack (.tif)
    if chan_number %Check for correction based on structural channel
        stack = stack(:,:,chan_number:2:end); %Just convert reference channel
    end
    stackInfo.nFrames(i) = size(stack,3);
    save(mat_paths{i},'stack');
end

%Console display
[path,~,~] = fileparts(mat_paths{1});
disp(['Stacks saved as .MAT in ' path]);
disp(['Time needed to convert files: ' num2str(toc) ' seconds.']);
warning(w); %revert warning state

