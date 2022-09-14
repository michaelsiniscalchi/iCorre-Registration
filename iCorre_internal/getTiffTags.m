function tags = getTiffTags(pathname)

t = Tiff(pathname); %Waaay faster than imfinfo.m (1000x)
tagNames = ["ImageWidth","ImageLength","BitsPerSample","SamplesPerPixel",...
    "SampleFormat","Compression","PlanarConfiguration","Photometric","ImageDescription"];
for j = 1:numel(tagNames)
    tags.(tagNames(j)) =  t.getTag(tagNames(j));
end