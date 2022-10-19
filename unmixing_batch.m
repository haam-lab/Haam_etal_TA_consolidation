% 2022a
% Extract data for a specific wavelength range and
% unmix spectra using a gc and td reference file
% Created by Juhee Haam, 
% input files: a) file(s) to be unmixed; b) gc and reference file (col1 as wavelength; col2 as gc reference;
% col3 as td reference without a header)
% output file(s): normalized ratio of gc to td coeff

clc;
clear;


% set working directory (where input and output files are located)
user= getenv('username');
startFolder = ['C:\Users\' user '\Box\NIEHS_ph\'];
groupFolder = uigetdir(startFolder,'Select a project folder (Parent Directory Where Input and Ouput folders Are Stored)');

% select reference file for unmixing
[ref_file, ref_path] = uigetfile('*.csv', 'Select the reference file for unmxing', [startFolder '2_Reference-for-unmixing\']);
ref_mat = readmatrix([ref_path ref_file]); % this is S (subspectra)

% set the range of wavelength you want to extract
waveL_Limit = 450;
waveU_Limit = 750;

% Designate where the extracted files will be sotred: inFile for unmixing
defaultOutFileFolder = [groupFolder '\Unmixing\outFiles\'];
[~,~,~] = mkdir(defaultOutFileFolder);
outFileFolder  = uigetdir(defaultOutFileFolder,'Designate the folder where unmixed data files will be stored');

% optional file saving
extractedFolder = [groupFolder '\Unmixing\inFiles\'];
fsExtraFolder = [groupFolder '\Fs\Extra\'];
spectrumFolder = [groupFolder '\Traces\Spectrum\'];
unmixedSpectrumFolder = [groupFolder '\Traces\unmixedSpectrum\'];
traceFolder = [groupFolder '\Traces\'];
fsFolder = [groupFolder '\Fs\'];

[~,~,~] = mkdir(extractedFolder);
[~,~,~] = mkdir(fsExtraFolder);
[~,~,~] = mkdir(spectrumFolder);
[~,~,~] = mkdir(unmixedSpectrumFolder);
[~,~,~ ] = mkdir([outFileFolder '\Extra\']);
[~,~,~ ] = mkdir([outFileFolder '\Extra\GT\']);
[~,~,~ ] = mkdir([outFileFolder '\Extra\R_sqr\']);
[~,~,~ ] = mkdir([outFileFolder '\Ratio\']);
[~,~,~] = mkdir(traceFolder);


%% fileInfo (select the right file when the popup window shows up)
[fileName,folderName] = uigetfile('*.txt','Select multiple files',groupFolder,'MultiSelect','on');

if iscell(fileName)== 0
    inFileName{1} = fileName;
else
    inFileName = fileName;
end

fileCount = size(inFileName,2);

for mm = 1:fileCount

name = regexp(inFileName{mm},'(\d+)[\-\_]+(.*)_Sub.*','tokens'); % this is better if you have multiple - or _
dateID = name{1,1}{1,1};
recordingInfo = name{1,1}{1,2};

% file names/label
inFile = [folderName inFileName{mm}];
fileLabel = [dateID '-' recordingInfo];



%% extract the data and analyze

[dataArray, fsReal, s1] = extract_photometry(inFile, waveL_Limit,waveU_Limit);
% dataArray = extracted data
% s1 = spectrum

%% OPTIONAL: save the extracted data

% sub_for_unmixing = [extractedFolder fileLabel '_forU.csv']; % save the extraction for unmixing
% writematrix(dataArray, sub_for_unmixing); % if you want to save the
% extracted data

%% OPTIONAL: read the first data row to plot spectrum

title([fileLabel '-spectrum']);
saveas(s1, [spectrumFolder fileLabel '-spectrum'],'jpeg');

dataSize = size(dataArray,1);

% save the summary
summary = cell(2,2);
summary(:,1) = {'Real fs'; 'Frame number' }; 
summary(:,2) = {fsReal ; dataSize };


outfileFs = [fsFolder fileLabel '-fsReal_U.xlsx'];
writecell(summary, outfileFs);

%% Read the extracted file (infile, previously) and perform unmixing

reference = ref_mat(:,2:end); % This is  S (components)

dataArray = dataArray(2:end,:); % Remove the first row (wavelength info)

timeLength = size(dataArray,1);
waveLength = size(dataArray,2);
resnorm = zeros(1,timeLength);
residual= zeros(waveLength,timeLength);
f = dataArray';   

A = zeros(2,timeLength);
for ii= 1: timeLength
    [A(:,ii),resnorm(ii),residual(:, ii)] = lsqnonneg(reference,f(:,ii)); % two component (time) for each frame (column)
end

gc2 = A(1,:)';
td2 = A(2,:)';

ratio2 = (A(1,:)./A(2,:))';
avg2 = mean(ratio2);
norm2 = (ratio2-avg2)/avg2*100;

%% Verfication ONLY: residual, R-squared, and normalized gc and td

% calculate other R-squared (calculated for each time point)
avg_f = zeros(1,timeLength);
ssf_mat = zeros(1,timeLength);


% calculate the total sum of variance

for ii = 1:timeLength
    avg_f(ii) =  mean(f(:, ii));
    ssf = 0;
    for k = 1:waveLength
        ssf = ssf + (f(k,ii))^2;
        ssf_mat(ii) = ssf;
    end
end

% Calculate the residual
f1 = zeros(waveLength,timeLength);
for ii = 1:timeLength
    f1(:,ii) = f(:,ii)-reference*A(:,ii);
end


% calculate the R-squared for each time point
R_sqr = zeros(1,timeLength);

for ii=1:timeLength
    R_sqr(1,ii) = 1-resnorm(ii)/ssf_mat(ii);
end

gc_avg = mean(gc2);
gc_N = (gc2-gc_avg)/gc_avg*100;

td_avg = mean(td2);
td_N = (td2-td_avg)/td_avg*100;


% plot the results (traces)
h = figure;
set(gcf,'position',[127 64 1680 906])
subplot(4,1,1)
plot(gc2); title([fileLabel 'Unmixing       GCamp' ]); 
ylim([min(gc2)-1 max(gc2)]);
subplot(4,1,2)
plot(td2); title('Tdtomato');
ylim([min(td2)-1 max(td2)]);
subplot(4,1,3)
plot(ratio2); title('ratio');
subplot(4,1,4);
plot(norm2); title('Ratio (% F/F0)'); xlabel('Frame#');
ylim([-20 20]);

% Optional: plot and file saving

% plot the unmixed spectrum (frame number cane be designated -time point)
frame_num = 20;
mixed = dataArray(frame_num,:)'; 
unmixed = reference*A(:,frame_num);
wavelength = ref_mat(:,1);
h5= figure; plot(wavelength, mixed, 'k'); hold on; plot(wavelength, unmixed, 'r');
title({[dateID recordingInfo]; ['-mixed(k) vs unmixed(r) without intercept -frame#:' num2str(frame_num)]}); 
text(520, max(td2)*0.6, {['R-squared =' num2str(R_sqr(1))];['Gcamp =' num2str(gc2(frame_num))]; ['tdTomato =' num2str(td2(frame_num))]});
saveas(h5,[unmixedSpectrumFolder dateID '-' recordingInfo '-unmixed spectrum'],'fig');

% save the results
saveas(h,[traceFolder fileLabel '-traces_unmx'],'fig');

outfileGc = [outFileFolder '\Extra\GT\' fileLabel '-unmix_gc.csv'];
outfileTd = [outFileFolder '\Extra\GT\' fileLabel '-unmix_td.csv'];
writematrix(gc2, outfileGc);
writematrix(td2, outfileTd);

outfileRatio2 = [outFileFolder '\Ratio\' fileLabel '-unmix_Ratio.csv'];
writematrix(ratio2, outfileRatio2);

outfileR_sqr = [outFileFolder '\Extra\R_sqr\' fileLabel '-unmix_R_sqr.csv'];
writematrix(R_sqr', outfileR_sqr);

%% Save unmixed data  (normalized ratio)
outfileNorm2 = [outFileFolder '\' fileLabel '-unmix_N.csv']; % this will be used for spectrogram
writematrix(norm2, outfileNorm2);

fprintf('Unmixing for %s is completed \n', inFileName{mm});
close all;
end

    
toc;