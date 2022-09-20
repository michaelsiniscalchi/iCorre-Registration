%%
tifFile = ('C:\Data\2-Photon Imaging\Sessions for Batch Processing\220210 M413 test\raw\220210 M413 T6_00002_00024.tif');


%ScanImage Tiff Reader Transposes image
[stack.SI, description, metadata] =  loadtiffseq(tifFile); % load raw stack (.tif)
redIdx = 2:2:size(stack.SI,3);
figure('Name','SI'); imagesc(mean(stack.SI(:,:,redIdx),3));
stack.SIt = pagetranspose(stack.SI);
figure('Name','SIt'); imagesc(mean(stack.SIt(:,:,redIdx),3));
% --- These read methods are consistent with ImageJ ---

%%
stack.tiffVolume = tiffreadVolume(tifFile);
figure('Name','tiffVolume'); imagesc(mean(stack.tiffVolume(:,:,redIdx),3));

%%
tic;
t = Tiff(tifFile);
for i = 1:size(stack.SI,3)
    t.setDirectory(i);
    stack.tiff(:,:,i) = t.read;
end
toc
figure('Name','tiffLib'); imagesc(mean(stack.tiff(:,:,redIdx),3));

%% The answer is that the ScanImage TiffReader page-transposes the image.
%Speed tests for transpose methods

tic;
stack2 = permute(stack.SI,[2,1,3]);
toc

tic;
stack1 = pagetranspose(stack.SI);
toc

figure('Name','permute'); imagesc(mean(stack2(:,:,redIdx),3));


