function [index] = getIndexAscending(array, value, lowerLimit)
% Get the index from a sorted array
% Created by Juhee Haam

% Input arguments:
% - array: input data (sorted data)
% - value: this function will find the index that meets the value (based on
% lower upper limit)
% - lowerLimit: boolean (1, lower limit; 0, upper limit)

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

k = 1;
while k < length(array)
    if array(k)> value
        if lowerLimit == 1
            index = k - 1;  % low limit of 1 Hz
        else 
            index = k;
        end
        break
    end
    k = k + 1;    
end
end