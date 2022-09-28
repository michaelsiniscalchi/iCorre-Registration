function stackInfo = parseTiffHeader(tif_file)
[fname,fpath] = uigetfile('C:\Data\2-Photon Imaging\Registered\220210 M413 T6\raw\*.tif');
tif_file = fullfile(fpath,fname);

[stack, desc, meta] = loadtiffseq(tif_file);
stackInfo.imageWidth    = size(stack,2);
stackInfo.imageHeight   = size(stack,1);
stackInfo.nFrames = size(stack,3);

%Text-scan header string to find specific parameter names
D = textscan(meta,'%s%s','Delimiter',{'='});

metaStruct = struct(...
    'frameRate','SI.hRoiManager.scanFrameRate ',...
    'zoomFactor','SI.hRoiManager.scanZoomFactor ',...
    'chans','SI.hChannels.channelSave ',...
    'power', 'SI.hBeams.powers ',...
    'PMT_tripped','SI.hPmts.tripped ');

fields = fieldnames(metaStruct);
metaStrings = struct2cell(metaStruct);
for i = 1:numel(fields)
    idx = strcmp(D{1},metaStrings{i});
    stackInfo.(fields{i}) = str2num(D{2}{idx}); %#ok<ST2NM>
end



% 'SI.hScan2D.sampleRate '
% 'SI.hScan2D.channelsDataType '

% 'SI.hPmts.tripped '