%fpath = 'X:\Addie_Lindsay\July2021_Stress2P\2p\suite2p\854\7-15-21\suite2p\plane0\data_chan2.bin';
fpath = 'X:\Addie_Lindsay\July2021_Stress2P\2p\suite2p\854\7-15-21\suite2p\plane0\data.bin';

% ONE BIN PER SESSION...WAY TOO LARGE TO TRY ON DESKTOP...
%   LOOK INTO SCOTTY 
%   OR TRY ON SPOCK
%   OR MAKE TEST BIN FILE FIRST...

fID = fopen(fpath);
nX = 512;
nY = 512;
nFrames = 1000;
[ data, count ] = fread(fID,nX*nY*nFrames,'*int16');

fclose(fID);

stack = permute(reshape(data,nY,nX,[]),[2,1,3]); %Binary data were saved in row order
figure;
imagesc(mean(stack,3));

