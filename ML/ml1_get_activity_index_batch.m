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
activity_index_folder = [projectFolder '\activity_index\'];
[~,~,~] = mkdir(activity_index_folder);

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
%% Calculate activity index by reading each frame (part or the whole video)
% Set an ROI for video analysis
roiPos = round([186.0847 246.0370 855.3699 468.1623]); % default
frame = 10; % Default frame number for ROI
figure; video1= read(v, frame);
imshow(video1);
rectangle('position', roiPos); % show the ROI 
% (OPTIONAL) Draw a rectangle to designate a new ROI for analysis
% figure; video1= read(v, frame);
% imshow(video1);
% roi = drawrectangle;
% roiPos = round(roi.Position);

endFrame = len; 
tic;
activity_index = zeros(endFrame-1,1);
se = strel('disk', 5); % this defines the neighbors

v.CurrentTime = 0; % initiate the video
clear frame_prev
k = 1;
activity_prev = false(960,1280); % initialize for the second frame.
while hasFrame(v)
    frame_cur = readFrame(v); frame_cur = imcrop(frame_cur, roiPos);
    frame_cur = rgb2gray(frame_cur); 
    frame_cur = imgaussfilt(frame_cur, sigma);
    frame_cur = imdilate(frame_cur, se);
    frame_cur = imerode(frame_cur, se);
    if k > 1
        diff = frame_cur-frame_prev;
        activity = abs(diff) > activity_thr;
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
img_size = roiPos(3)*roiPos(4);
activity_index = activity_index/img_size*100; 

toc;
len = length(activity_index);
time = 1/fs/2 : 1/fs :1/fs*(len-1) + 1/fs/2;
H0 = figure; set(gcf,'position', [104 45 1400 600]);
plot(time, activity_index,'k'); set(gca,'fontSize',12); xlim('tight'); 
set(gca,'color','none','XColor','k','YColor','k','FontSize',16, 'GridLineStyle','none');box off; 
title(['Activity index-' fileInfo '-dil-sigma, ' num2str(sigma) '-thr' num2str(activity_thr) '-v1_3_8']); 
ylabel('Activity Index'); 
yline(std(activity_index)*2,'r--');

%% Save the output file
activity_outName = [activity_index_folder fileInfo '_activity_index.csv'];
writematrix([time' activity_index], activity_outName);
saveas(H0,[activity_index_folder fileInfo '_activity_Fig'],'fig');
fprintf('Analysis for %s is completed \n', inFileName{mm});

end