% Train an ensemble ML model using train data sets.
% Created by Juhee Haam

% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
% EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
% OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
% IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
% DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
% ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
% DEALINGS IN THE SOFTWARE.

% Input data:
% - Predictor data (7 feature data), generated from ml2_extract_features (each
% column contains each feature data)
% - Response data (true state classification from EEG/EMG data)

% Output data:
% - ML model (classify as sleep (2) or waking (0))

%% directory
user= getenv('username');
startFolder = ['C:\Users\' user];
%% Load predictor and response data from multiple files
[fileName, pathName] = uigetfile('*.csv', 'Select predictor file(s)', startFolder, 'multiSelect', 'on');

if iscell(fileName)== 0
    inFileName{1} = fileName;
else
    inFileName = fileName;
    inFileName = sort(inFileName);
end

fileCount = size(inFileName,2);
predCell = cell(fileCount, 1);


for file = 1:fileCount
predCell{file} = readmatrix([pathName inFileName{file}]); % input file name
end


[fileName0, pathName0] = uigetfile('*.csv', 'Select manual scoring file(s)', manualScoringFolder, 'multiSelect', 'on');
fileName0 = sort(fileName0);

if iscell(fileName0)== 0
    inFileName{1} = fileName0;
else
    inFileName = fileName0;
end

fileCount = size(inFileName,2);
trueStateTcell = cell(fileCount,1);

for file = 1:fileCount
trueStateTcell{file} = readmatrix([pathName0 inFileName{file}]); % input file name
end

predSetTrain = cell2mat(predCell);
trueState = cell2mat(trueStateTcell);

% trim
len = min(size(predSetTrain,1), size(trueState,1));
predSetTrain = predSetTrain(1:len, :);
trueState = trueState(1:len,:);


%% Train a model
trainDataInput = array2table(predSet, 'VariableNames', {'feature_1', 'feature_2', 'feature_3', 'feature_4','feature_5','feature_6','feature_7'});
predictorNames = {'feature_1', 'feature_2', 'feature_3', 'feature_4','feature_5','feature_6','feature_7'};
predictors = trainDataInput(:, predictorNames);

classNames = [0; 2];

tempTree = templateTree(...
    'MaxNumSplits', 10099, ...
    'NumVariablesToSample', 'all');

trainedModel = fitcensemble(predictors, trueState, 'Method', 'Bag', ...
    'NumLearningCycles', 30, ...
    'Learners', tempTree, ...
    'Cost', [0 1; 1 0], ...
    'ClassNames', classNames,  'CategoricalPredictors', []); 

% Perform cross-validation
cvModel = crossval(trainedModel, 'KFold', 5);

% Compute validation accuracy
accuracyCV = 1 - kfoldLoss(cvModel, 'LossFun', 'ClassifError');
disp(accuracyCV);
