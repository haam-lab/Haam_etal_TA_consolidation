% Calculate motion index (similar to Ethovision activity) from video data
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
blk_size = 1000; % number of frames that are read together

%% directories
user= getenv('username');
% startFolder = ['C:\Users\' user];

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
num_frmblk = floor(endFrame/blk_size);
activity_index = zeros(endFrame-1,1);
se = strel('square', 3); % this defines the neighbors
if (num_frmblk > 0)
    for ii = 1:num_frmblk % should be until endFrame
        video = read(v, [(ii-1)*blk_size+1 ii*blk_size]);
        for k = 1:blk_size-1
             video1 = video(:,:, 1, k); 
            % video1 =imresize(video1, down_factor, 'nearest'); % downsample 
            % figure; imshow(video1);
            video1 = imgaussfilt(video1, sigma); % the default sigma, 0.5
            video2 = video(:, :, 1, k+1); 
            % video2 =imresize(video2, down_factor, 'nearest'); % downsample 
            video2 = imgaussfilt(video2, sigma); % the default sigma, 0.5
            diff =  video1 - video2;
            activity = abs(diff) > activity_thr;
            activity = imerode(activity,se);   
            activity = imdilate(activity, se);  
            activity_count =  find(activity==1);
            if isempty(activity_count)==1
                activity_index((ii-1)*blk_size+k) = 0;
            else
                activity_index ((ii-1)*blk_size+k) = length(activity_count);
            end   
        end
    end
end

% read the last frame block
frame_partial = endFrame - num_frmblk*blk_size;
if frame_partial > 0
    video = read(v, [num_frmblk*blk_size+1 num_frmblk*blk_size+frame_partial]);
    for k = 1:frame_partial-1
        video1 = video(:,:, 1, k); 
        % video1 =imresize(video1, down_factor, 'nearest'); % downsample 
        video1 = imgaussfilt(video1, sigma); % the default sigma, 0.5
        video2 = video(:, :, 1, k+1); 
        % video2 =imresize(video2, down_factor, 'nearest'); % downsample 
        video2 = imgaussfilt(video2, sigma); % the default sigma, 0.5
        diff =  video1 - video2;
        activity = abs(diff) > activity_thr;
        activity = imerode(activity,se);   % erosion step %% add very little additional time
        activity = imdilate(activity, se);  % dilation step
        activity_count =  find(activity==1);
        if isempty(activity_count)==1
            activity_index(num_frmblk*blk_size+k) = 0;
        else
            activity_index (num_frmblk*blk_size+k) = length(activity_count);
        end   
    end
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