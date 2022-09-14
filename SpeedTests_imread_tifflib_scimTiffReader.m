fullpath = 'C:\Data\TaskLearning_VTA\data\220311 M413 T7\raw\220311 M413 T6_00001_00020.tif';

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