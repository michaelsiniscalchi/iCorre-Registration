function stackInfo = get_stackInfo_iCorre( raw_path, params)

disp('Fetching stackInfo: metadata from image files...');

%Disable warning
% warning('off','imageio:tiffmexutils:libtiffWarning'); %Warning: TIFF library warning - 'TIFFFetchNormalTag:  ASCII value for tag "ImageDescription" does not end in null byte.'
warning('off');

switch params.scim_ver
    
    case 3
        %Header info from scim_openTif()
        header = scim_openTif(raw_path{1});
        stackInfo.imageWidth    = header.acq.pixelsPerLine;
        stackInfo.imageHeight   = header.acq.linesPerFrame; %The corresponding tiff tag will be 'imageLength' (if 'tiff2mat.m' is used, proper tiff tags are stored in stackInfo.tags)
        stackInfo.frameRate     = header.acq.frameRate;
        stackInfo.zoomFactor    = header.acq.zoomFactor;
        stackInfo.nChans        = header.acq.numberOfChannelsSave;
        
        for i = 1:numel(raw_path)
            
            %Waitbar
            f = waitbar(0);
            msg = ['Processing stack ' num2str(i) '/' num2str(numel(raw_path)) '...'];
            waitbar(i/numel(raw_path),f,msg);
            
            %Filename from raw substacks
            [~,fname,ext] = fileparts(raw_path{i});
            stackInfo.rawFileName{i} = [fname ext];
            
            %Number of frames per substack
            stackInfo.nFrames(i)    = length(imfinfo(raw_path{i}))/stackInfo.nChans;
            
            %Get trigger timestamp and delay from scim_openTif()
            header = scim_openTif(raw_path{i}); %Get header info
            trigTime = datetime(header.internal.triggerTimeString,'InputFormat','M/d/yyyy H:m:s.SSS'); %As datetime for easier calculations
            firstTrigTime = datetime(header.internal.triggerTimeFirstString,'InputFormat','M/d/yyyy H:m:s.SSS');
            
            %Store trigger time as difference in seconds between current trigger and first trigger timestamps
            stackInfo.trigTime(i) = seconds(trigTime - firstTrigTime); %Time from first trigger in seconds
            stackInfo.trigDelay(i) = header.internal.triggerFrameDelayMS/1000; %Delay in seconds between trigger and time of first pixel in frame
            
        end
        
    case 5
        %scim_openTif() does not work for files acquired with ScanImage ver. 5
        %opentif() could be used, but seems to require the whole ScanImage software package.
        %For now, the native MATLAB imfinfo() function will be used.
        %However, ScanImage-specific metadata can not be extracted this way...
        info = imfinfo(raw_path{1});
        stackInfo.imageWidth    = info(1).Width;
        stackInfo.imageHeight   = info(1).Height; %The corresponding tiff tag will be 'imageLength' (if 'tiff2mat.m' is used, proper tiff tags are stored in stackInfo.tags)
        stackInfo.frameRate     = []; %Header info needed from class ScanImageTiffReader() or opentif(); opentif() seems to depend on ScanImage Software package
        stackInfo.zoomFactor    = [];
        stackInfo.nChans        = ...
            any(find(cell2mat(struct2cell(params.split_channels)))) + 1; % == false+1 = 1 if 1-channel; == true+1 = 2 if 2-channel
                    
        for i = 1:numel(raw_path)
            
            %Waitbar
            f = waitbar(0);
            msg = ['Processing stack ' num2str(i) '/' num2str(numel(raw_path)) '...'];
            waitbar(i/numel(raw_path),f,msg);
            
            %Filename from raw substacks
            [~,fname,ext] = fileparts(raw_path{i});
            stackInfo.rawFileName{i} = [fname ext];
            
            %Number of frames per substack
            stackInfo.nFrames(i)    = length(imfinfo(raw_path{i}))/stackInfo.nChans;
            
%  *** Following Block Needs Updating Using Functions From ScanImage 5, eg opentif() or class ScanImageTiffReader:
%
%             %Get trigger timestamp and delay from scim_openTif()
%             header = scim_openTif(raw_path{i}); %Get header info
%             trigTime = datetime(header.internal.triggerTimeString,'InputFormat','M/d/yyyy H:m:s.SSS'); %As datetime for easier calculations
%             firstTrigTime = datetime(header.internal.triggerTimeFirstString,'InputFormat','M/d/yyyy H:m:s.SSS');
%             
%             %Store trigger time as difference in seconds between current trigger and first trigger timestamps
%             stackInfo.trigTime(i) = seconds(trigTime - firstTrigTime); %Time from first trigger in seconds
%             stackInfo.trigDelay(i) = header.internal.triggerFrameDelayMS/1000; %Delay in sec
        end
end


%All column vectors
fields = fieldnames(stackInfo);
for i = 1:numel(fields)
    stackInfo.(fields{i}) = stackInfo.(fields{i})(:);
end

%Re-enable warnings
warning('on');

%Close progress bar
close(f);