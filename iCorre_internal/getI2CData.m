%%% getI2CData()
%
% PURPOSE: To extract I2C data sent by ViRMEn and written to the TIFF header during image acquisition. 
%
% AUTHOR: MJ Siniscalchi, PNI, 220315
%
% INPUT ARGUMENTS:
%       'img_desc' a cell array of image descriptions, populated from the ImageDescription tags 
%           associated with each frame (IFD) within a TIFF file.  
% 
% Extract tags using the MATLAB Tiff class, eg:
%
%   t = Tiff(file_path);
%   img_desc = cell(numIFDs,1); %Initialize cell array
%   for i = 1:numIFDs %For each frame
%       t.setDirectory(i);
%       img_desc{i} = t.getTag("ImageDescription");
%   end
%   
% Or using the ScanImage TiffReader, eg:
%
%   import ScanImageTiffReader.ScanImageTiffReader; %Import TiffReader class
%   reader = ScanImageTiffReader(full_path); %Create reader object
%   img_desc = reader.descriptions; %Extract frame-varying metadata
%---------------------------------------------------------------------------------------------------

function data = getI2CData(img_desc) 

%Initialize
[frameNumber, uint8_data, time] = deal(cell(numel(img_desc),1)); %Cell arrays to store multiple values per frame
droppedIdx = false(numel(img_desc),1); %Idx for frames where I2C packets were not received by ScanImage

% Extract I2C data for each frame
for i = 1:numel(img_desc) 
        %Parse variable names/values
        D = textscan(img_desc{i},'%s%s','Delimiter',{'='});
        
        %Frame numbers
        idx = strcmp(D{1},'frameNumbers ');
        frameNumber{i} = str2double(D{2}{idx});
        
        %I2C data
        idx = strcmp(D{1},'I2CData ');
        dataChar = erase(D{2}{idx},{'{','}','[',']'}); %Remove superfluous delimiters
        if ~isempty(dataChar)
            % Current format of I2C data in ViRMEn is 
            % '{{double(img_time), typecast([blockIdx,trialIdx,iteration],'uint8')} }'
            % eg, '{{49.933671315, [2,0,6,0,97,0]} }'
            dataCell = textscan(dataChar,...
                '%f %u8 %u8 %u8 %u8 %u8 %u8','Delimiter',','); 
            time{i} = dataCell{:,1}; %I2C Time stamp
            frameNumber{i} = repmat(frameNumber{i},size(time{i},1),1); %Duplicate frame number for multiple I2C packets/frame  
            %Trial idx, blockidx, and iteration
            uint8_data{i} = [dataCell{:,2:end}]; %Stored as 2-element little-endian uint8 vectors
        else
            droppedIdx(i,:) = true; %Record indices of any dropped I2C packets
        end
end

%Frame numbers
data.frameNumber = vertcat(frameNumber{~droppedIdx}); %Discard frame numbers for dropped I2C data
%Time from first imaging frame
data.t = vertcat(time{:}); %From I2C data
%Block, Trial, & Iteration
uint8_data = vertcat(uint8_data{~droppedIdx}); %Concatenate cell contents
uint16_data = zeros(size(uint8_data,1),3,'uint16'); %Initialize columns for Block, Trial, Iteration
for i = 1:size(uint8_data,1)
    %Convert from uint8 to uint16, eg [2,0,5,0,71,1] to [2,5,327]
    uint16_data(i,:) = typecast(uint8_data(i,:),'uint16'); 
end
data.blockIdx = uint16_data(:,1); %ViRMEn block index
data.trialIdx = uint16_data(:,2); %ViRMEn trial index
data.iteration = uint16_data(:,3); %ViRMEn iteration within a trial