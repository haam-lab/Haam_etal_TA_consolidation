% Calculate motion index from video data and identify freezing. 
% Created by Juhee Haam

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

% Input data
% - Video file(s) (e.g., mp4, avi)
% - Parameters listed below

% Output data
% - Motion index and freezing classfication (active,0; freezing, 1) (.csv)
% - Motion index graph with components (MATLAB fig)
% - Summary stat (.xlsx)

% Custom funtions needed:
% - applyMinimumDur.m (J.Haam)

clc;
clear;

%% Parameters
% Designate the right protocol among the ones % listed below (comment the others);
% protocol = 'context'; % option #1: 8 min context test
protocol = 'delay_3ts'; % option #2: delay 3 tone shock pairing
% protocol = 'trace_3ts'; % option #3: trace 3 tone shock pairing

% Parameters for motion and freezing detection: 
motion_thr = 22 ; % this is the minimum change in the intensity to be counted as a pixel that has changed.
fz_thr= 100; % this needs to be adjusted based testing on a few videos.
min_frame = 3; % minimum number of frame below the threshold to be detected as freezing; 
sigma= 1; % sigma for gaussian filtering
fs = 4; % video sampling frequency

%% Components
% - Each row contains 'component name', [start frame:end 
% frame] 

if strcmp(protocol,'context') ==1
component = {'min1', 1:240;
    'min2', 240:480;
    'min3', 480:720;
    'min4', 720:960;
    'min5', 960:1200;
    'min6', 1200:1440;
    'min7', 1440:1680;
    'min8', 1680:1912;
    'total' 1:1912};
elseif strcmp(protocol,'delay_3ts') == 1
    component = {'BSL', 1:720;
    'Tone1', 720:800;
    'Shock1', 792:800;
    'ITI1', 800:1600;
    'Tone2', 1608:1688;
    'Shock2', 1680:1688;
    'ITI2', 1688:2488;
    'Tone3', 2496:2576;
    'Shock3' 2568:2576;
    'ITI3', 2576:3368;
    'Total', 1:3368};
elseif strcmp(protocol,'trace_3ts') == 1
    component = {'BSL', 1:720;
    'Tone1', 720:800;
    'Shock1', 880:888;
    'ITI1', 800:1600;
    'Tone2', 1608:1688;
    'Shock2', 1768:1776;
    'ITI2', 1688:2488;
    'Tone3',2496:2576;
    'Shock3' 2656:2664;
    'ITI3', 2576:3368;
    'Trace1', 800:880;
    'Trace2', 1688:1768;
    'Trace3', 2576:2656;
    'Total', 1:3368};  
end
%% directories
user= getenv('username');
startFolder = ['C:\Users\' user];

projectFolder = uigetdir(startFolder,'Select a project folder (Parent directory Where Input and Ouput folders Are Stored)');
summaryFolder = [projectFolder '\Summary\'];
[~,~,~] = mkdir(summaryFolder);

%% Select a video file when a pop-up window shows up
% [fileName, pathName] = uigetfile('*.avi', 'Select a video file', groupFolder);
[fileName,pathName] = uigetfile('*.avi','Select multiple video files',projectFolder,'MultiSelect','on');

if iscell(fileName)== 0
    inFileName{1} = fileName;
else
    inFileName = fileName;
    inFileName = sort(inFileName);
end

fileCount = size(inFileName,2);

for mm = 1:fileCount

name = regexp(inFileName{mm},'(.*)_Video.avi','tokens');    % remove _Video.csv
fileInfo = name{1,1}{1,1};

v = VideoReader([pathName inFileName{mm}]); 

len = v.NumFrames;
vidH = v.Height;
vidW = v.Width;

%% Calculate motion index by reading each frame (part or the whole video)
endFrame = len-1; % optional trimming if a speicfic endframe is put in here.
motion_index = zeros(endFrame,1);
se = strel('square', 3); % this defines the neighbors

v.CurrentTime = 0; % initiate the video
clear frame_prev
k = 1;
activity_prev = false(v.Height,v.Width); % initialize for the second frame.
while hasFrame(v)
    frame_cur = readFrame(v);
    frame_cur=  0.2989 * frame_cur(:,:, 1) + 0.5870 * frame_cur(:,:, 2) + 0.1140 * frame_cur(:,:, 3); 
    frame_cur = imgaussfilt(frame_cur, sigma);
    if k > 1
        diff = frame_cur-frame_prev;
        motion = abs(diff) > motion_thr;
        motion = imerode(motion,se);   
        motion = imdilate(motion, se); 
        motion_count =  find(motion==1); 
        if isempty(motion_count)==1
            motion_index(k-1) = 0;
        else
            motion_index (k-1) = length(motion_count);
        end 
    end   
    frame_prev = frame_cur;
    k = k+1;
end

len = length(motion_index);
time = 0 : 1/fs :1/fs*(len-1) ;
H0 = figure; set(gcf,'position', [104 45 1400 600]);
subplot(211); plot( motion_index,'k'); set(gca,'fontSize',12); xlim('tight');
set(gca,'color','none','XColor','k','YColor','k','FontSize',16, 'GridLineStyle','none');box off; 
title(['Motion index-' fileInfo '-dil-sigma, ' num2str(sigma)]); 
ylabel('Motion Index'); yline(fz_thr,'r--');

if strcmp(protocol,'delay_3ts') == 1 || strcmp(protocol,'trace_3ts')  == 1 
    col_1 = {min(component{2,2}), max(component{2,2});
        min(component{5,2}), max(component{5,2});
        min(component{8,2}), max(component{8,2})};
    col_2 = {min(component{3,2}), max(component{3,2});
    min(component{6,2}), max(component{6,2});
    min(component{9,2}), max(component{9,2})}; 
    for ii = 1:3
        x1 = [col_2{ii,1}-1/fs,col_2{ii,2}-1/fs,col_2{ii,2}-1/fs,col_2{ii,1}-1/fs];
        x2 = [col_1{ii,1}-1/fs,col_1{ii,2}-1/fs,col_1{ii,2}-1/fs,col_1{ii,1}-1/fs];
        y2 = [0, 0, max(motion_index)*1.1, max(motion_index)*1.1];
        patch(x2, y2, 'm', 'FaceAlpha',.2, 'edgecolor', 'none');
        patch(x1, y2, 'g', 'FaceAlpha',.4, 'edgecolor', 'none');
    end
end

%% Detect freezing and save freezing stat for each component
% define freezing (immobility should be longer than the minimum frame number)
% - need the custom function applyMinimumDur
frzCls = (motion_index < fz_thr);
frzCls2 = applyMinimumDur(frzCls,min_frame);
subplot(212); 
plot(frzCls2,'k'); set(gca,'fontSize',12); xlim('tight'); ylim([-1 2]);yticks([0 1]);
set(gca,'color','none','XColor','k','YColor','k','FontSize',16, 'GridLineStyle','none');box off; 
xlabel('Frame number');
ylabel('Mobile(0) vs. Freezing(1)'); 

% get stat for each component
componentNum = size(component,1);
frzComp = cell(componentNum,1);
for ii = 1:componentNum
    ind_frz = find(frzCls2(component{ii,2}) ==1);

    if isempty(ind_frz)==1
        frzComp{ii} = 0;
    else
        frzComp{ii} = (length(ind_frz))/(length(component{ii,2}))*100;
    end
    clear ind_frz;
end

% OPTIONAL: save the output files
summary = cell(componentNum+5,4);
summary(1:4, 1:4) = {'motion threshold', motion_thr, '', ''; 
    'freezing threshold', fz_thr, 'component protocol', protocol; 
    'minimum frames for freezing', min_frame, '', '';
    'Total frame number', len, '', ''};
summary(5, 1:4) = {'Component', 'Start frame', 'End frame', 'Freezing (%)'};
summary(6:end, 1) = component(:,1);
summary(6:end, 4) = frzComp;
for ii=1:componentNum
    summary(5+ii, 2:3) = {min(component{ii,2}),max(component{ii,2})};
end

motion_cell = cell(length(frzCls2)+1,2);
motion_cell(1,:) = {'Motion index', 'Freezing'};
motion_cell(2:end, 1) = num2cell(motion_index);
motion_cell(2:end, 2) = num2cell(frzCls2);

outfileSummary = [summaryFolder fileInfo '_freezingStat.xlsx'];
writecell(summary, outfileSummary);
motion_outName = [summaryFolder fileInfo '_motion_freezing.csv'];
writecell(motion_cell, motion_outName);
saveas(H0,[summaryFolder fileInfo '_motionFig'],'fig');
fprintf('Analysis for %s is completed \n', inFileName{mm});

end