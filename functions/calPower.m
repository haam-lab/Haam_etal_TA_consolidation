function [power,powerWake, powerSleep] = calPower(photometry,fs, binSize, params, sleepCls, lowlim, highlim)
% Calculate delta for each bin and acquire stat of delta during waking/sleep
% states
% Written by Juhee Haam, 2023

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

% Input arguments
%   photometry: time series photometry data
%   fs: the sampling frequency of photometry data 
%   params [optional]: parameters for the multi-taper method 
%   binSize: bin size for the quantification of power of specific band
%   sleepCls: sleep/wake state
%   lowlim: low limit of the band of interest
%   highlim: high limit of the band of interest

% Output arguments
%   power: power of a specified band (each bin)
%   powerWake: delta power during waking
%   powerSleep: delta power during sleep

% Required functions
% - custom function: getIndexAscending.m  (JH)

if nargin < 6
    disp('Not enough input arguments')
end

movingWin = [binSize, binSize];

if isempty(params)
    params.tapers = [3 5];      
    params.Fs = fs;   
    params.fpass = [0 12]; % designate the frequency range
    params.err = [1 0.05]; 
end


freq_low = 0.5; 
freq_high = 12;
[b,a] = butter(3,[freq_low/(fs/2) freq_high/(fs/2)],'bandpass');
filt_ratio = filtfilt(b, a, photometry);


[spectrogram,t,f,~] = mtspecgramc(filt_ratio, movingWin, params);

% find 1hz column (use the custom function, getIndexAscending)
lowHz = getIndexAscending(f,lowlim, 1);
highHz = getIndexAscending(f, highlim, 1);

power  = zeros(length(t),1);
for ii = 1:length(t)
    power (ii) = trapz(f(lowHz+1:highHz), spectrogram(ii, lowHz+1:highHz));
end


% trim the files
if diff([length(sleepCls), length(power)]) > 1
    warndlg('There is significant discrepancy between the number of video frames and photometry acquisition') ;
end

diff_frame = length(power)-length(sleepCls);
fprintf('Photometry#-video# is %f frames \n', diff_frame);

len = min(length(sleepCls), length(power));
sleepCls = sleepCls(1:len);
power = power(1:len);

% wake vs. sleep 
groupSynd = cell(1,2);
groupSynd{1} = power(sleepCls == 0);
groupSynd{2} = power(sleepCls == 1);

powerWake.values = groupSynd{1};
powerSleep.values = groupSynd{2};

powerWake.Median = median(groupSynd{1});
powerSleep.Median = median(groupSynd{2});

powerWake.Mean = mean(groupSynd{1});
powerSleep.Mean = mean(groupSynd{2});

powerWake.Num = length(groupSynd{1});
powerSleep.Num = length(groupSynd{2});

powerWake.SEM = std(groupSynd{1})/powerWake.Num;
powerSleep.SEM = std(groupSynd{2})/powerSleep.Num;



end