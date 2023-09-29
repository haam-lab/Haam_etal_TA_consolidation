function [mod_index] = applyMinimumDur(source_index, min_dur)
% Calculate total freezing duration / total time, bout frequency, bout duration
% Created by Juhee Haam

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

% Input arguments:
% - Source_index: source boolean matrix
% - Min_dur: minimum duration in frames to be detected as a valid event (e.g.
% freezing if it lasted more than x frames)

% Output argument are organized as following: first hour, second hour, ..., total
% - mod_index: new boolean matrix after only selecting bouts at least the minimum
% duration 

mod_index = zeros(size(source_index));

imobIndex = find(source_index  == 1);
imobCount = length(imobIndex);

event = 1; k = 1;
imobBout.Start(1)= imobIndex(1);
for ii = 2:imobCount
    if imobIndex(ii - 1) == imobIndex(ii) - 1
        k = k + 1;
        
    else
        imobBout.DurBin(event) = k; 
        event = event + 1; 
        imobBout.Start(event)= imobIndex(ii);
        k = 1; % reset the count
    end
    
    if ii == imobCount % will count the last (incomplete) bout also
        imobBout.DurBin(event) = k;
    end
end


for ii = 1:length(imobBout.Start)
    if imobBout.DurBin(ii) >= min_dur
        for k = 1:imobBout.DurBin(ii)
             mod_index(imobBout.Start(ii)-1+k) = 1; 
        end
    end

end

