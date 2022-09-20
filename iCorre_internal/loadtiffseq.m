
function [ stack, tags, ImageDescription] = loadtiffseq( full_path, method )

if nargin<2
    method = 'TiffLib'; %Default; slower than ScanImageTiffReader, but does not require OS-specific MEX files
end

get_descriptions = true;
if nargout<2
    get_descriptions = false;
end

%Initialize stack and get image descriptions
% if strcmp(method,'imread') || strcmp(method,'TiffLib')
%     info = imfinfo(full_path);
%     nX = info(1).Width;
%     nY = info(1).Height;
%     nZ = numel(info);
%     stack = zeros(nX,nY,nZ,'int16');
%     descriptions = {info.ImageDescription};
%     metadata = []; %Not available without ScanImageTiffReader
% end

%Get frame-invariant tags
t = Tiff(full_path);
tagNames = ["ImageWidth","ImageLength","BitsPerSample","SamplesPerPixel",...
    "SampleFormat","Compression","PlanarConfiguration","Photometric"]; %,"ImageDescription"
for i = 1:numel(tagNames)
    tags.(tagNames(i)) =  t.getTag(tagNames(i));
end
metadata = []; %Only available with ScanImageTiffReader

switch method
    
    case 'TiffLib'    
        %Initialize outputs
        while ~t.lastDirectory
            t.nextDirectory;
        end
        nFrames = t.currentDirectory;
        stack = zeros(tags.ImageLength, tags.ImageWidth, nFrames,'int16');

        %Read frames
        for i = 1:nFrames
            t.setDirectory(i);
            stack(:,:,i) = t.read();
            if get_descriptions %Frame-specific tags: I2C data, etc.
                tags.ImageDescription{i,1} =  t.getTag("ImageDescription");
            end
        end
        close(t);

    case 'scim'
        %Import TiffReader
        import ScanImageTiffReader.ScanImageTiffReader; %Requires OS-specific MEX files
        %Extract Data
        reader = ScanImageTiffReader(full_path); %Create reader object
        stack = permute(reader.data,[2,1,3]); %TiffReader transposes data relative to TiffLib/ImageJ (and every other MATLAB reader)
%         descriptions = reader.descriptions; %Frame-varying metadata; also obtained with tags.ImageDescription
        metadata = reader.metadata(); %Frame-invariant metadata
end

%---------------------------------------------------------------------------------------------------
% Comment 2202118 MJ Siniscalchi:
%
% Use ScanImage TiffReader Class! Waaay faster than previous approaches
% -just requires additional parsing of header info)
% -unfortunately, it seems to transpose the data...why??
%
%---------------------------------------------------------------------------------------------------
% Comment 191212 MJ Siniscalchi:
%
%After 2019a, imread() works similarly, but read(t) takes forever...
%
% imread() on a 9415 frame stack:
%Elapsed time is 11.148636 seconds. (2019a)
%Elapsed time is 11.230316 seconds. (2019b)
%
% tiff.read() on same stack :
%Elapsed time is 12.358082 seconds.  (2019a) - so, slightly slower than imread()...
%Elapsed time is 377.836698 seconds. (2019b) - tremendously slower (??)

%-----------------------***PREVIOUS VERSIONS***-----------------------------------------------------
%
% info = imfinfo(pathname);
%
% nX = info(1).Width;
% nY = info(1).Height;
% nZ = numel(info);
% D=zeros(nX,nY,nZ,'uint16');  %Initialize
%
% % Populate 3D array with imaging data from TIF file
% for i=1:nZ
%     D(:,:,i)=imread(pathname,i,'Info',info);
% end
%
% -------------------------------------
% AC Kwan: code below tested 3.37sec
%http://www.matlabtips.com/how-to-load-tiff-stacks-fast-really-fast/
% t = Tiff(pathname,'r');
% for i=1:nZ
%    t.setDirectory(i);
%    D(:,:,i)=t.read();
% end
% t.close();

% MJS tried this syntax, and it does not work either in MATLAB 2019b...
% if strcmp(method,'tifLib')
%     t = Tiff(pathname,'r');
%     for i=1:nZ
%         setDirectory(t,i);
%         D(:,:,i) = read(t);
%     end
%     close(t);
% end
