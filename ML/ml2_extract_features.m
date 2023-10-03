% Extract features from activity data (from video data)
% Created by Juhee Haam

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

% Input data:
%   Activity data (pixel change-based)(.csv) from video data: This is acquired using
%   ml_get_Activity_index_batch.m and has a 2-column structure (First
%   column, timestamp; Second column: Activity data)

% Output data:
% - 7 features (saved in the data folder)
% - figures showing the time course of the features and spectrogram

%% Parameters
binSize =10; % in sec; this should correspond to the training data
actCutoff = 10; % conservative threshold for the active state, above of which is grouped together for histogram

%% Directory
user= getenv('username');
startFolder = ['C:\Users\' user];
projectFolder = uigetdir(startFolder,'Select a project folder (Parent directory Where Input and Ouput folders Are Stored)');
features_folder = [projectFolder '\features\'];
data_folder = [features_folder '\data\'];
figure_folder = [features_folder '\figures\'];
[~,~,~] = mkdir(features_folder);
[~,~,~] = mkdir(data_folder);
[~,~,~]  = mkdir(figure_folder);

%% Select a video file when a pop-up window shows up
% [fileName, pathName] = uigetfile('*.avi', 'Select a video file', groupFolder);
[fileName,pathName] = uigetfile('*.*','Select activity files',projectFolder,'MultiSelect','on');

if iscell(fileName)== 0
    inFileName{1} = fileName;
else
    inFileName = fileName;
    inFileName = sort(inFileName);
end

fileCount = size(inFileName,2);

for mm = 1:fileCount
%% Import data and get the file name info for output files
name = regexp(inFileName{mm},'(.*).csv','tokens');    % remove .csv
fileInfo = name{1,1}{1,1};
import = readmatrix([pathName inFileName{mm}]); % input file name
activity = import(:,2);
fs = 1/(import(2,1) - import(1,1));

%% Features 1-4 extraction
actBin.size = floor(size(activity,1)/fs/binSize);
actBin.data = cell(actBin.size,1);
actBin.mean = zeros(1, actBin.size);
actBin.std = zeros(1, actBin.size);
actBin.median = zeros(1, actBin.size);
actBin.base = zeros(1, actBin.size);

% data put in each bin
for ii = 1:actBin.size
    actBin.data {ii,1} = activity(floor(fs*binSize*(ii-1))+1:floor(fs*binSize*ii),1);
end

% get average, std, and median for each bin 
for ii = 1:actBin.size
    actBin.mean(ii) = mean(actBin.data{ii});
    actBin.std(ii) = std(actBin.data{ii});
    actBin.median(ii) = median(actBin.data{ii});
    edges = [0:0.1:actCutoff,30];
    N = histcounts(actBin.data {ii,1},edges);  
    actBin.base  (ii) = edges(round(mean(find(N == max(N)))));
end

%% Features 5-7 extraction 
freq_low = 0.5; % default is 0.5
freq_high = 10;
[b,a] = butter(3,[freq_low/(fs/2) freq_high/(fs/2)],'bandpass');
filt_activity = filtfilt(b, a, activity);

% filter for spectrogram
freq_low = 1; % default is 1
freq_high = 10;
[b,a] = butter(3,[freq_low/(fs/2) freq_high/(fs/2)],'bandpass');
filt_activity_spectrogram = filtfilt(b, a, activity);

params.tapers = [3 5];      
params.Fs = fs;   % sampling frequency
params.fpass = [0 10]; % designate the frequency range
params.err = [1 1]; 
movingWin = [10 10]; % [winsize winstep]
[spectrogram,t,f,Serr] = mtspecgramc(filt_activity,movingWin,params);

h0 = figure; set(gcf, 'position', [44 100 2000 300]);
ax1 = axes('Parent',h0);
plot_matrix(spectrogram,t,f);
set(ax1, 'fontSize', 12); % note that this number is relative! Not same as the power shown in spectra
title([fileInfo '-rFs'], 'fontSize', 12);
colormap jet; set(gca,'color','none','XColor','k','YColor','k'); box off;

%% Calculate power of each band (for this quantification, [0 10] filter was used instead of [0.5 10])
% find indeces for 1, 4, 6, and 10 Hz
oneHz = getIndexAscending(f,1, 1);
fourHz = getIndexAscending(f,4, 1);
sixHz = getIndexAscending(f,6, 1);

% calculate the power of each band
timeLength = size(spectrogram,1);
power0_1 = zeros(oneHz,1);
power1_4  = zeros(timeLength,1);
power6_10  = zeros(timeLength,1);

for ii = 1:timeLength
    power0_1(ii) = trapz(f(1:oneHz), spectrogram(ii, 1:oneHz));
    power1_4 (ii) = trapz(f(oneHz+1:fourHz), spectrogram(ii, oneHz+1:fourHz));
    power6_10 (ii) = trapz(f(sixHz+1:end), spectrogram(ii, sixHz+1:end));
end

%% Plot activity data and all features
feature_data = [actBin.mean', actBin.std', actBin.median', actBin.base', power0_1, power1_4, power6_10]; % each column contains each feature
label_data = {'Mean', 'Std', ' Median', 'Base', '0-1 Hz power', '1-4 Hz power', '6-10 Hz power' };
timestamp = 1/2/fs:1/fs:1/2/fs+(length(activity)-1)*1/fs;
timeBin = binSize:binSize:actBin.size*binSize;
h1 = figure; 
set(h1, 'position',[168         175        2241        1145]);
subplot(4,2,1); 
plot(timestamp, activity); xlim('tight');
title([fileInfo '-activity index'], 'fontSize', 12); xlabel('Time (s)'); set(gca, 'fontSize', 12);
set(gca,'color','none','XColor','k','YColor','k'); box off;
for ii = 1:7
    subplot(4,2,ii+1);
    plot(timeBin, feature_data(:,ii)); xlim('tight');
    title(['Feature #' num2str(ii) ': ' num2str(binSize) 's-bin ' label_data{ii}], 'fontSize', 12);
    xlabel('Time (s)'); set(gca, 'fontSize', 12); set(gca,'color','none','XColor','k','YColor','k'); box off;
end

%% Save output data
featureDataName = [data_folder fileInfo '-7feature_data.csv'];
writematrix(feature_data, featureDataName);
saveas(h0, [figure_folder fileInfo '-spectrogram'],'fig');
saveas(h1, [figure_folder fileInfo '-features'],'fig');
fprintf('Feature extraction from %s is completed \n', inFileName{mm});

end
