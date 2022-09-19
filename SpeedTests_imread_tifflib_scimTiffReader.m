fullpath = 'C:\Data\TaskLearning_VTA\data\220311 M413 T7\raw\220311 M413 T6_00001_00020.tif';
fullpath = 'C:\Data\TaskLearning_VTA\data\220311 M413 T7\NRMC_220311 M413 T6_00001_0_DS30.tif';
%% imfinfo()
tic;
info = imfinfo(fullpath);
nX = info(1).Width;
nY = info(1).Height;
nZ = numel(info);
description = info.ImageDescription;
disp('imfinfo():');
toc

%% Tiff() 
tic;
%Get specified tags
t = Tiff(fullpath);
tagNames = ["ImageWidth","ImageLength","BitsPerSample","SamplesPerPixel",...
    "SampleFormat","Compression","PlanarConfiguration","Photometric","ImageDescription"];  %,"ImageDescription"
for i = 1:numel(tagNames)
    tags.(tagNames(i)) =  t.getTag(tagNames(i));
end

%Initialize stack
while ~t.lastDirectory
    t.nextDirectory;
end
nFrames = t.currentDirectory;
stack = zeros(tags.ImageLength, tags.ImageWidth, nFrames,'int16');

%Read frames
for i = 1:nFrames
    t.setDirectory(i);
    stack(:,:,i) = t.read();
end
close(t);

disp('Tiff():');
toc

%% imread()
tic;
info = imfinfo(fullpath);
nX = info(1).Width;
nY = info(1).Height;
nZ = numel(info);

disp('imfinfo():');
toc

tic;
% Populate 3D array with imaging data from TIF file
imData = zeros(nX,nY,nZ,'int16');  %Initialize
for i=1:nZ
    imData(:,:,i)=imread(fullpath,i,'Info',info);
end
disp('imread():');
toc

%% TiffLib
tic;
t = Tiff(fullpath);
tiffData = zeros(nX,nY,nZ,'int16');  %Initialize
for i=1:nZ
    setDirectory(t,i);
    tiffData(:,:,i) = read(t);
end
close(t);
disp('TiffLib:');
toc

%% ScanImageTiffReader
%Import TiffReader
import ScanImageTiffReader.ScanImageTiffReader;

%Extract Data
tic;
reader = ScanImageTiffReader(fullpath); %Create reader object
stack = permute(reader.data,[2,1,3]); %TiffReader transposes data relative to TiffLib/ImageJ (and every other MATLAB reader)
descriptions = reader.descriptions; %Frame-varying metadata
metadata = reader.metadata(); %Frame-invariant metadata
disp('Scim:');
toc

%% loadtiffseq()
% tic;
% [stack, tags, metadata] =  loadtiffseq(fullpath,'TiffLib'); % load raw stack (.tif)
% toc

tic;
[stack, ImageDescription, ~] =  loadtiffseq(tif_paths{i},options.read_method); % load raw stack (.tif)
toc

tic;
[stack, ~, ~] =  loadtiffseq2(tif_paths{i},options.read_method); % load raw stack (.tif)
toc