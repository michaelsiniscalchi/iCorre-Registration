%imfinfo()

% 1500 frame file
[fname,fpath] = uigetfile('C:\Data\2-Photon Imaging\Registered\220201 M412 T6_grid64\raw\*.tif');
InfoImage = imfinfo(fullfile(fpath,fname));
tic; InfoImage=imfinfo(fullfile(fpath,fname)); toc
% Elapsed time is 19.358912 seconds.

% 300 frame file
[fname,fpath] = uigetfile('C:\Data\2-Photon Imaging\Registered\220210 M413 T6\raw\*.tif');
tic; InfoImage=imfinfo(fullfile(fpath,fname)); toc
% Elapsed time is 140.630839 seconds.

% Loading pixel data
tic;
stack = loadtiffseq(fpath,fname); % load raw stack (.tif)
toc %Old version, 25-35 s on 300f stack

tic;
stack = loadtiffseq(fpath,fname);
toc %New version using TiffReader: 0.28 s!

%ScanImageTiffReader
%Import TiffReader
import ScanImageTiffReader.ScanImageTiffReader;
%Extract Data
tic;
reader=ScanImageTiffReader(fullfile(fpath,fname));
toc

data = reader.data();
meta = reader.metadata();
desc = reader.descriptions();

for i = 1:numel(desc)
D = textscan(desc{1},'%s','Delimiter',{' = '});
end

% SI.hChannels.channelSave = [1;2]

%ScanImage Util Function
tic;
[header,~,imgInfo] = scanimage.util.opentif(fullfile(fpath,fname));
toc