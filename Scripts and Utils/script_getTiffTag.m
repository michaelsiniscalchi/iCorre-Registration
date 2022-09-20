t = Tiff('C:\Data\2-Photon Imaging\Sessions for Batch Processing\220311 M413 T7_1-100\raw\220311 M413 T6_00001_00001.tif');
img_desc = cell(numIFDs,1); %Initialize cell array
for i = 1:numIFDs %For each frame
    t.setDirectory(i);
    img_desc{i} = t.getTag("ImageDescription");
end