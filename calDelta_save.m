% Calculate delta power in diferent states (sleep vs. wake)
% Created by Juhee Haam, 11/11/2022 

% Required custom functions
% - getIndexAscending.m  (JH)
% - calDetal.m (JH)
% - compareTwoGroups.m (JH)

clear;
clc;

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
params.fpass = [0 10]; % designate the frequency range
params.err = [1 0.05]; 
movingWin = [10 10]; 

%% filter the data and plot a spectrogram (note that moving window and step size are both 10s unlike typical spectrogram)

[delta,deltaWake, deltaSleep] = calDelta(photometry,fs, binSize, params, sleepCls);
[p_val,testType, stats, graph1] = compareTwoGroups(deltaWake.values, deltaSleep.values, 0);

%% stats

statSummary_W_S = cell(6,3);
statSummary_W_S(2:6,1) = {'Median'; 'Mean'; 'SEM'; 'Bin Count'; 'Waking vs. Sleep'};
statSummary_W_S(1,2:3) = {'Waking', 'Sleep'};
statSummary_W_S(2:5,2) = {deltaWake.Median; deltaWake.Mean; deltaWake.SEM; deltaWake.Num};
statSummary_W_S(2:5,3) = {deltaSleep.Median; deltaSleep.Mean; deltaSleep.SEM; deltaSleep.Num};
statSummary_W_S(6,2:3) = {testType, p_val}; 


% optional plot
figure; 
subplot(211); plot(sleepCls); ylim([-1 3]);
subplot(212); plot(delta);
