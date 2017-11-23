clear all;
close all;

% Add the path to the data folder so that MATLAB can access it
addpath([pwd '/Data']);

% Create a path to the text file with all the subjects
path='RDKCenterVsPeriphery_Subjects.txt';
% Make an ID for the subject list file
subjectListFileId=fopen(path);
% Read in the number from the subject list
numberOfSubjects = fscanf(subjectListFileId,'%d');

% Read the subject ID from the file, stop after each line
subjectId = fscanf(subjectListFileId,'%s',[1 1]);
% Print out the subject ID
fprintf('subject: %s\n',subjectId);

% Import the data
Alldata = load(['structure_data_' subjectId '.mat']); 
dataStructure = Alldata.data;

%---------------------%
%   Practice trials   %
%---------------------%

% Get the indices of the easy practice trials
easyPracticeTrialsArrayIndices = returnIndices(dataStructure.difficulty, 'easy');
% Use the indices to get the array of whether they got it correct, and then
% sum them up.
numberOfCorrectPracticeTrials = sum(dataStructure.correct(easyPracticeTrialsArrayIndices));
disp(['numberOfCorrectPracticeTrials: ' num2str(numberOfCorrectPracticeTrials)]);


%---------------------%
%      Coherence      %
%---------------------%

% Get indices of the actual trials
actualTrialIndices = returnIndices(dataStructure.trialType,'actual');

% ----CENTER----

% Get the indices for the center
centerIndices = returnIndices(dataStructure.positionType, 'center');

% Get the intersection of two arrays as the actual and center trial indices
actualCenterIndices = intersect(actualTrialIndices,centerIndices);

% Minus 1 to all the indices to match up with the RDK indices
actualCenterIndices = actualCenterIndices - 1;

% Index out the center coherences
centerCoherence = returnValues(dataStructure.coherence, actualCenterIndices);

% ----PERIPHERY----

% Get the indices for the center
peripheryIndices = returnIndices(dataStructure.positionType, 'periphery');

% Get the intersection of two arrays as the actual and center trial indices
actualPeripheryIndices = intersect(actualTrialIndices,peripheryIndices);

% Minus 1 to all the indices to match up with the RDK indices
actualPeripheryIndices = actualPeripheryIndices - 1;

% Index out the center coherences
peripheryCoherence = returnValues(dataStructure.coherence, actualPeripheryIndices);

% ----PLOT----

% Plot a staircase
plotStaircase(centerCoherence,peripheryCoherence);

