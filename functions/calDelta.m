function [delta,deltaWake, deltaSleep] = calDelta(photometry,fs, binSize, params, sleepCls)
% Calculate delta for each bin and acquire stat of delta during waking/sleep
% states
% Written by Juhee Haam, 2022

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
%   binSize: bin size for the quantification of delta power

% Output arguments
%   delta: delta power (each bin)
%   deltaWake: delta power during waking
%   deltaSleep: delta power during sleep

% Required functions
% - custom function: getIndexAscending.m  (JH)

if nargin < 4
    disp('Not enough input arguments')
end

movingWin = [binSize, binSize];

if isempty(params)
    params.tapers = [3 5];      
    params.Fs = fs;   
    params.fpass = [0 10]; % designate the frequency range
    params.err = [1 0.05]; 
end


freq_low = 0.5; 
freq_high = 10;
[b,a] = butter(3,[freq_low/(fs/2) freq_high/(fs/2)],'bandpass');
filt_ratio = filtfilt(b, a, photometry);


[spectrogram,t,f,~] = mtspecgramc(filt_ratio, movingWin, params);

% find 1hz column (use the custom function, getIndexAscending)
oneHz = getIndexAscending(f,1, 1);
fourHz = getIndexAscending(f, 4, 1);

delta  = zeros(length(t),1);
for ii = 1:length(t)
    delta (ii) = trapz(f(oneHz+1:fourHz), spectrogram(ii, oneHz+1:fourHz));
end


% trim the files
if diff([length(sleepCls), length(delta)]) > 1
    warndlg('There is significant discrepancy between the number of video frames and photometry acquisition.');
end

len = min(length(sleepCls), length(delta));
sleepCls = sleepCls(1:len);
delta = delta(1:len);

% wake vs. sleep 
groupSynd = cell(1,2);
groupSynd{1} = delta(sleepCls == 0);
groupSynd{2} = delta(sleepCls == 1);


deltaWake.Median = median(groupSynd{1});
deltaSleep.Median = median(groupSynd{2});

deltaWake.Mean = mean(groupSynd{1});
deltaSleep.Mean = mean(groupSynd{2});

deltaWake.Std = std(groupSynd{1});
deltaSleep.Std = std(groupSynd{2});

deltaWake.Num = length(groupSynd{1});
deltaSleep.Num = length(groupSynd{2});

end