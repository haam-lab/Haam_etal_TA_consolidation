% Get prediction data using the ensemble ML model 
% Created by Juhee Haam

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

% Input data:
% - 7 feature data (predictors), generated from ml2_extract_features (each
% column contains each feature data)

% Output data:
% - Prediction data using the ML model (sleep,2; waking, 0)

%% Directories
% Open the input data
user= getenv('username');
startFolder = ['C:\Users\' user];
projectFolder = uigetdir(startFolder,'Select a project folder (Parent directory Where Input and Ouput folders Are Stored)');
predictionFolder = [projectFolder '\prediction\']; 
[~,~,~]  = mkdir(predictionFolder);

%% Select a predictor data set when a pop-up window shows up
[fileName,pathName] = uigetfile('*.csv','Select a predictor data set',projectFolder); 
name = regexp(fileName,'(.*).csv','tokens');    % remove .csv
fileInfo = name{1}{1};
predSetData = readmatrix([pathName fileName]); % input file name

%% Predict responses using the ML model
user= getenv('username');
[fileName,pathName] = uigetfile('*.*','Select a model',startFolder);
load([pathName fileName]);  
yfit1 = predict(trainedModel, predSetData); 
writematrix(yfit1, [predictionFolder fileInfo '-predResults.csv']);
