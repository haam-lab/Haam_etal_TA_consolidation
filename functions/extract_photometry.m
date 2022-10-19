function [dataArray, fsReal, s1] = extract_photometry(inFile, waveL_Limit,waveU_Limit)
% extract photometry data from acquisition from QE-Pro spectrometer 

% Input arguments
%   inFile: [pathName fileName]
%   waveL_Limit: lower limit of the wavelength to be extracted
%   wavUL_Limit: upper limit of the wavelength to be extracted

% Output arguments
%   dataArray: extracted data with the first row wavelength
%   s1: spectrum from a single time point

% Written by Juhee Haam (modified from unmixing_batch, JH), 2022


if nargin <3
    disp('Not enough input arguments')
end


%% extract the data and analyze
% pattern to analyze the txt file
formatSpec_c = '%s %*[^\n]'; 
delimiter  = '\t';

% read the first column
fid = fopen(inFile,'r');
firstColumn = textscan(fid, formatSpec_c, 'Delimiter',delimiter); % the header will be less than 50 lines though.
fclose(fid);

% find where data starts
content = firstColumn{1};
lineNumber = find(strcmp(content,'>>>>>Begin Spectral Data<<<<<'));
headerlineNumber = lineNumber+1;

% read the wavelength row
formatSpec_w = '%f';
fid = fopen(inFile,'r');
wavelength = textscan(fid, formatSpec_w,'HeaderLines',lineNumber,'Delimiter',delimiter); 
fclose(fid);
waveValues = wavelength{1,1}(3:end);


% determine the gc and td columns
k = 1;
while k < 2000 
    if waveValues(k,1)> waveL_Limit
        waveStart = k;
        break  
    end
    k = k + 1;
end


k = 1;
while k < 2000 
    if waveValues(k,1)> waveU_Limit
        waveEnd = k-1;
        break  
    end
    k = k + 1;
end


% read the file
dataLength = size(firstColumn{1},1)-headerlineNumber;
% if the recording was done without trigger, acquiaition for all
% wavelengths may not have been completed - subtract 1

formatSpec = ['%*s %*d' repmat('%*f',1,waveStart-1) repmat('%f',1,waveEnd-waveStart+1) '%*[^\n]']; % note that %*d skips the integer field
fid = fopen(inFile,'r');
temp= textscan(fid, formatSpec,'HeaderLines',headerlineNumber,'Delimiter',delimiter);  %dataArray (2:end, 2:end) 
fclose(fid);


% textscan to dataArray
dataArray = zeros(dataLength+1, waveEnd-waveStart+1); % considering that dataArray has the headers (wavelength, unixtime)
dataArray (1, :) = waveValues(waveStart:waveEnd)';

for ii = 1:size(temp,2)
    dataArray(2:dataLength+1,ii) = temp{ii}(1:dataLength); % trim to dataLengh
end

% plot: spectrum
count = size(waveValues,1);
formatSpec_s = ['%*s %*d' repmat('%f',1,count) '%*[^\n]'];
fid = fopen(inFile,'r');
start  = lineNumber + 1;
firstV = textscan(fid, formatSpec_s, 1,'HeaderLines',start,'Delimiter',delimiter); 
fclose(fid);
first = cell2mat(firstV);
s1 = figure; set(gcf, 'position', [423 142 1186 857]); plot(waveValues,first);

%% calculate fs
% read the second column
formatSpec_t = '%*s %s %*[^\n]';  % second column
fid = fopen(inFile,'r');
secondColumn = textscan(fid, formatSpec_t,'HeaderLines',headerlineNumber, 'Delimiter',delimiter); 
fclose(fid);

timeU = secondColumn{1};
dataSize = size(timeU,1);
content = secondColumn{1};
durAct = str2double(content{dataSize})-str2double(content{1}); % in ms
fsReal = dataSize/durAct*1000;


end