% Calculate power of band (delta, theta, etc) in diferent states (sleep vs.
% wake) and the average power during both states
% Created by Juhee Haam, 5/4/2023 from calDelta_save

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

% Input files
% 1) Normalized photometry data (e.g., delta F/F0)
% 2) Binary sleep classification data (e.g., 0 for waking; 1 for sleep)

% Sleep classification based on video data
% As video fs is based on video tag (which is 25 Hz), and all data were
% frame-locked, the same fs should be used for photometry rather than using the
% time stamp from photometry data. 

% Required custom functions
% - getIndexAscending.m  (JH)
% - calPower.m (JH)
% - compareTwoGroups.m (JH)

clear;
clc;

lowlim = 1; % for delta
highlim = 4; % for delta
binSize = 10;
fs = 25; % sampling rate

user= getenv('username');
startFolder = ['C:\Users\' user ];


%% Read photometry data 
% Select a file when a pop-up window shows up
[fileName, pathName] = uigetfile('*.csv', 'Select a photometry file', startFolder);
name = regexp(fileName,'(.*).csv','tokens');    % remove .csv
fileInfo = name{1}{1};

inFilePath = [pathName fileName];
photometry = readmatrix(inFilePath); % input file name


%% Read video-based sleep-wake classification dat
[fileName, pathName] = uigetfile('*.csv', 'Select a sleep clssificatio file', startFolder);
nameV = regexp(fileName,'(.*).csv','tokens');    % remove .csv

inFilePath = [pathName fileName];
sleepCls = readmatrix(inFilePath); % input file name

%% Parameters for frequency domain analysis
params.tapers = [3 5];      
params.Fs = fs;   
params.fpass = [0 12]; % designate the frequency range
params.err = [1 0.05]; 
movingWin = [10 10]; 

%% filter the data and plot a spectrogram (note that moving window and step size are both 10s unlike typical spectrogram)
[power, powerWake, powerSleep] = calPower(photometry,fs, binSize, params, sleepCls, lowlim, highlim);

len = min(length(sleepCls), length(power));
sleepCls = sleepCls(1:len);
power = power(1:len);

[p_val,testType, stats, graph1] = compareTwoGroups(powerWake.values, powerSleep.values, 0);
%% stats
statSummary_W_S = cell(6,4);
statSummary_W_S(2:6,1) = {'Median'; 'Mean'; 'SEM'; 'Bin Count'; 'Waking vs. Sleep'};
statSummary_W_S(1,2:4) = {'Waking', 'Sleep', ' Total'};
statSummary_W_S(2:5,2) = {powerWake.Median; powerWake.Mean; powerWake.SEM; powerWake.Num};
statSummary_W_S(2:5,3) = {powerSleep.Median; powerSleep.Mean; powerSleep.SEM; powerSleep.Num};
statSummary_W_S(2:5,4) = {median(power); mean(power); std(power)/sqrt(length(power)); length(power)};
statSummary_W_S(6,2:3) = {testType, p_val}; 

% optional plot
h1=figure; set(gcf,'Position', [336   157   560   420])
timeV = 5:10:5+10*(length(sleepCls)-1);
subplot(211); 
plot(timeV, sleepCls); ylim([-1 3]); xlim('tight'); yticks([0 ,1]); yticklabels({'W','S'}); ylabel('State');
set(gca,'color','none','XColor','k','YColor','k','FontSize',16, 'GridLineStyle','none');box off;
subplot(212); plot(timeV, power);set(gca,'color','none','XColor','k','YColor','k','FontSize',16, 'GridLineStyle','none');box off;
xlabel('Time (s)'); xlim('tight');

