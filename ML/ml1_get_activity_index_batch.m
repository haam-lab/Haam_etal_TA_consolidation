% Calculate activity index from video data
% Created by Juhee Haam

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

% Iuput data:
% - Video data (e.g., avi, mp4, etc)

% output data:
% - 2-column matrix: First column, timestamp; Second column: Activity data (.csv)
% - Activity data plot

% Custom funtions needed:
% - applyMinimumDur.m (J.Haam)

clc;
clear;

%% Parameters for motion detection: 
activity_thr = 5 ; % changes in pixel value
sigma= 1; % sigma for gaussian filtering
fs = 25; % video sampling frequency
down_factor = 1; % image down sample factor (e.g., 0.25) (1 for no downsampling)

%% directories
user= getenv('username');
startFolder = ['C:\Users\' user];

projectFolder = uigetdir(startFolder,'Select a project folder (Parent directory Where Input and Ouput folders Are Stored)');
motion_index_folder = [projectFolder '\activity_index\'];
[~,~,~] = mkdir(motion_index_folder);

%% Select a video file when a pop-up window shows up
% [fileName, pathName] = uigetfile('*.avi', 'Select a video file', groupFolder);
[fileName,pathName] = uigetfile('*.*','Select multiple video files',projectFolder,'MultiSelect','on');

if iscell(fileName)== 0
    inFileName{1} = fileName;
else
    inFileName = fileName;
    inFileName = sort(inFileName);
end

fileCount = size(inFileName,2);

for mm = 1:fileCount
name = regexp(inFileName{mm},'(.*).mp4','tokens');    % remove .mp4
fileInfo = name{1,1}{1,1};

v = VideoReader([pathName inFileName{mm}]); 

len = v.NumFrames;
vidH = v.Height;
vidW = v.Width;
img_size = vidH * vidW*(down_factor)^2;
%% Calculate activity index by reading each frame (part or the whole video)
endFrame = len; % no trimming
% endFrame = 2000; % optional trimming if a speicfic endframe is put in here
activity_index = zeros(endFrame-1,1);
se = strel('square', 3); % this defines the neighbors
v.CurrentTime = 0; % initiate the video
clear frame_prev
k = 1;
activity_prev = false(960,1280); % initialize for the second frame.
while hasFrame(v)
    frame_cur = readFrame(v);
    frame_cur=  0.2989 * frame_cur(:,:, 1) + 0.5870 * frame_cur(:,:, 2) + 0.1140 * frame_cur(:,:, 3); 
    frame_cur = imgaussfilt(frame_cur, sigma);
    if k > 1
        diff = frame_cur-frame_prev;
        activity = abs(diff) > activity_thr;
        activity = imerode(activity,se);   
        activity = imdilate(activity, se); 
        activity_count =  find(activity==1); 
        if isempty(activity_count)==1
            activity_index(k-1) = 0;
        else
            activity_index (k-1) = length(activity_count);
        end 
    end   
    frame_prev = frame_cur;
    k = k+1;
end
    
% normalize the activity_index to the image size and scale
activity_index = activity_index/img_size*100*2; 

% plot
len = length(activity_index);
time = 1/fs/2 : 1/fs :1/fs*(len-1) + 1/fs/2;
H0 = figure; set(gcf,'position', [104 45 1400 600]);
plot(time, activity_index,'k'); set(gca,'fontSize',12); xlim('tight');
set(gca,'color','none','XColor','k','YColor','k','FontSize',16, 'GridLineStyle','none');box off; 
title(['Activity index-' fileInfo '-dil-sigma, ' num2str(sigma)]); 
ylabel('Activity Index'); 
yline(std(activity_index)*2,'r--');

%% Save the output file
activity_outName = [motion_index_folder fileInfo '_activity_index.csv'];
writematrix([time' activity_index], activity_outName);
saveas(H0,[motion_index_folder fileInfo '_activity_Fig'],'fig');
fprintf('Analysis for %s is completed \n', inFileName{mm});

end