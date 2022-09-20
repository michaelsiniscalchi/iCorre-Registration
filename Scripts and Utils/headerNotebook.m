
[fname,fpath] = uigetfile('C:\Data\2-Photon Imaging\Registered\220210 M413 T6\raw\*.tif');

t = Tiff(fullfile(fpath,fname)); %Waaay faster than imfinfo.m (1000x)

tagNames = ["ImageWidth","ImageLength","BitsPerSample","SamplesPerPixel",...
    "SampleFormat","Compression","PlanarConfiguration","Photometric"];
for i = 1:numel(tagNames)
    tags.(tagNames(i)) =  t.getTag(tagNames(i));
end

% Tiff.(tagNames(i)) gives enumeration for indexed tags