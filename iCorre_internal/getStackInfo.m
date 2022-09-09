function stackInfo = getStackInfo( stack, description, metadata )

%Basic image info
stackInfo.class = class(stack);
stackInfo.imageWidth    = size(stack,2);
stackInfo.imageHeight   = size(stack,1);

%Text-scan description to find date and time of file creation
if ~isempty(description)
    D = textscan(description,'%s%s','Delimiter',{'='});
    dateString = D{2}{strcmp(D{1},'epoch ')};
    stackInfo.startTime = datetime(str2num(dateString));
end

%Text-scan metadata to find specific parameters
if ~isempty(metadata)
    D = textscan(metadata,'%s%s','Delimiter',{'='});

    metaStruct = struct(...
        'frameRate','SI.hRoiManager.scanFrameRate ',...
        'zoomFactor','SI.hRoiManager.scanZoomFactor ',...
        'chans','SI.hChannels.channelSave ',...
        'power', 'SI.hBeams.powers ');  %'PMT_tripped','SI.hPmts.tripped ' could be useful but does not appear to work

    fields = fieldnames(metaStruct);
    metaStrings = struct2cell(metaStruct);
    for i = 1:numel(fields)
        idx = strcmp(D{1},metaStrings{i});
        value = str2num(D{2}{idx});  %#ok<ST2NM>
        stackInfo.(fields{i}) = (value(:)'); %Row vectors
    end
end

%---- Example for extracting additional stack-specific metadata -----------------------------
% (currently, fields such as 'SI.hPmts.tripped' do not appear to be used.)
%
% if nargin<3 %Write general metadata for whole session
%
%     %Basic image info
%     stackInfo.class = class(stack);
%     stackInfo.imageWidth    = size(stack,2);
%     stackInfo.imageHeight   = size(stack,1);
%
%     metaStruct = struct(...
%         'frameRate','SI.hRoiManager.scanFrameRate ',...
%         'zoomFactor','SI.hRoiManager.scanZoomFactor ',...
%         'chans','SI.hChannels.channelSave ',...
%         'power', 'SI.hBeams.powers ',...
%         'PMT_tripped','SI.hPmts.tripped ');
%
%     fields = fieldnames(metaStruct);
%     metaStrings = struct2cell(metaStruct);
%     for i = 1:numel(fields)
%         idx = strcmp(D{1},metaStrings{i});
%         value = str2num(D{2}{idx});  %#ok<ST2NM>
%         stackInfo.(fields{i}) = (value(:)'); %Row vectors
%     end
% elseif isfield(stackInfo,'nStacks') && length(stackInfo.nFrames) == 1
%     %Initialize variables for remaining stacks
%     stackInfo.nFrames = [stackInfo.nFrames; zeros(stackInfo.nStacks-1,1)]; %Number of frames in stack
%     stackInfo.PMT_tripped = [stackInfo.PMT_tripped; zeros(stackInfo.nStacks-1,1)]; %Indicator varable
%     stackInfo.stackIdx = 2; %Increment stack index
% else
%     stackInfo.stackIdx = stackInfo.stackIdx + 1; %Increment stack index
% end
%
% %Stack-Specific Data
% metaStruct = struct('PMT_tripped','SI.hPmts.tripped '); %Edit to add any additional stack vars
% fields = fieldnames(metaStruct);
% metaStrings = struct2cell(metaStruct);
% for i = 1:numel(fields)
%     idx = strcmp(D{1},metaStrings{i});
%     value = str2num(D{2}{idx});  %#ok<ST2NM>
%     stackInfo.(fields{i})(stackInfo.stackIdx,:) = (value(:)'); %Row vectors
% end
% stackInfo.nFrames(stackInfo.stackIdx,1) = size(stack,3)/numel(stackInfo.chans); %Number of frames in stack