close all;

% Switch parameters
saveStaircase = 0;

% Add the path to the data folder so that MATLAB can access it
addpath([pwd '/Data']);

% Create a path to the text file with all the subjects
path='RDKCenterVsPeriphery_Subjects.txt';
% Make an ID for the subject list file
subjectListFileId=fopen(path);
% Read in the number from the subject list
numberOfSubjects = fscanf(subjectListFileId,'%d');

%-----Prepare arrays to store data-----

% Store for Psy Mu
centerPsyMu20 = nan(numberOfSubjects,1);
peripheryPsyMu20 = nan(numberOfSubjects,1);
centerPsyMu100 = nan(numberOfSubjects,1);
peripheryPsyMu100 = nan(numberOfSubjects,1);

% Store for CSD Mu
centerCSDMu20 = nan(numberOfSubjects,1);
peripheryCSDMu20 = nan(numberOfSubjects,1);
centerCSDMu100 = nan(numberOfSubjects,1);
peripheryCSDMu100 = nan(numberOfSubjects,1);

% Store for Psy Sigma
centerPsySigma20 = nan(numberOfSubjects,1);
peripheryPsySigma20 = nan(numberOfSubjects,1);
centerPsySigma100 = nan(numberOfSubjects,1);
peripheryPsySigma100 = nan(numberOfSubjects,1);

% Store for CSD Mu
centerCSDSigma20 = nan(numberOfSubjects,1);
peripheryCSDSigma20 = nan(numberOfSubjects,1);
centerCSDSigma100 = nan(numberOfSubjects,1);
peripheryCSDSigma100 = nan(numberOfSubjects,1);

% Store for CSD K
centerCSDK20 = nan(numberOfSubjects,1);
peripheryCSDK20 = nan(numberOfSubjects,1);
centerCSDK100 = nan(numberOfSubjects,1);
peripheryCSDK100 = nan(numberOfSubjects,1);

%----Start looping and get the values----

for i = 1:1%numberOfSubjects
    
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
    numberOfCorrectEasyPracticeTrials = sum(dataStructure.correct(easyPracticeTrialsArrayIndices));
    disp(['numberOfCorrectPracticeTrials: ' num2str(numberOfCorrectEasyPracticeTrials)]);
    
    %Insert clause here where we only run the rest if the number of correct
    %trials is 8 and above (i.e. above 7)
    
    
    %---------------------%
    %      Coherence      %
    %---------------------%
    
    % Get indices of the actual trials
    actualTrialIndices = returnIndices(dataStructure.trialType,'actual');
    
    % ----CENTER----
    
    % Get the indices for the center
    centerIndices = returnIndices(dataStructure.positionType, 'center');
    
    % Get the intersection of two arrays as the actual and center trial indices
    actualCenterSimIndices = intersect(actualTrialIndices,centerIndices);
    
    % Minus 1 to all the indices to match up with the RDK indices
    actualCenterRDKIndices = actualCenterSimIndices - 1;
    
    % Index out the center coherences
    actualCenterCoherence = returnValues(dataStructure.coherence, actualCenterRDKIndices);
    
    % ----PERIPHERY----
    
    % Get the indices for the periphery
    peripheryIndices = returnIndices(dataStructure.positionType, 'periphery');
    
    % Get the intersection of two arrays as the actual and periphery trial indices
    actualPeripherySimIndices = intersect(actualTrialIndices,peripheryIndices);
    
    % Minus 1 to all the indices to match up with the RDK indices
    actualPeripheryRDKIndices = actualPeripherySimIndices - 1;
    
    % Index out the periphery coherences
    actualPeripheryCoherence = returnValues(dataStructure.coherence, actualPeripheryRDKIndices);
    
    % ----PLOT----
    
    % Plot a staircase
    figure;
    plotStaircase(actualCenterCoherence,actualPeripheryCoherence, i, subjectId, saveStaircase);
    
    %---------------------%
    %         CSD         %
    %---------------------%
    
    % ----CENTER----
    
    % Get the sim score for the center and divide by 100 to get range of 0 to 1
    actualCenterConfidenceJudgments = dataStructure.sim_score(actualCenterSimIndices)./100;
    
    % Get the binary form of the sim score
    actualCenterBinaryChoice = (actualCenterConfidenceJudgments > 0.5);
    
    % Get the coherent directions of the actual center trials
    actualCenterCoherentDirection = dataStructure.coherent_direction(actualCenterRDKIndices);
    
    % Fix the coherence array such that leftward direction is negative
    actualCenterFixedCoherence = fixCoherence(actualCenterCoherence, (actualCenterCoherentDirection == 180));
    
    % Invoke the CSD for 20 trials
    % Returns [mu, sigma, k, finalMu, finalSigma, finalK]
    centerCSD20Trials = startCSD(actualCenterFixedCoherence(1:20), actualCenterBinaryChoice(1:20), actualCenterConfidenceJudgments(1:20));
    
    % Store the values in the array
    centerPsyMu20(i) = centerCSD20Trials(1);
    centerPsySigma20(i) = centerCSD20Trials(2);
    centerCSDMu20(i) = centerCSD20Trials(4);
    centerCSDSigma20(i) = centerCSD20Trials(5);
    centerCSDK20(i) = centerCSD20Trials(6);
    
    % Invoke the CSD for 100 trials
    % Returns [mu, sigma, k, finalMu, finalSigma, finalK]
    centerCSD100Trials = startCSD(actualCenterFixedCoherence, actualCenterBinaryChoice, actualCenterConfidenceJudgments);
    
    % Store the values in the array
    centerPsyMu100(i) = centerCSD100Trials(1);
    centerPsySigma100(i) = centerCSD100Trials(2);
    centerCSDMu100(i) = centerCSD100Trials(4);
    centerCSDSigma100(i) = centerCSD100Trials(5);
    centerCSDK100(i) = centerCSD100Trials(6);
    
    
    % ----PERIPHERY----
    
    % Get the sim score for the periphery and divide by 100 to get range of 0 to 1
    actualPeripheryConfidenceJudgments = dataStructure.sim_score(actualPeripherySimIndices)./100;
    
    % Get the binary form of the sim score
    actualPeripheryBinaryChoice = (actualPeripheryConfidenceJudgments > 0.5);
    
    % Get the coherent directions of the actual periphery trials
    actualPeripheryCoherentDirection = dataStructure.coherent_direction(actualPeripheryRDKIndices);
    
    % Fix the coherence array such that leftward direction is negative
    actualPeripheryFixedCoherence = fixCoherence(actualPeripheryCoherence, (actualPeripheryCoherentDirection == 180));
    
    % Invoke the CSD for 20 trials
    % Returns [mu, sigma, k, finalMu, finalSigma, finalK]
    peripheryCSD20Trials = startCSD(actualPeripheryFixedCoherence(1:20), actualPeripheryBinaryChoice(1:20), actualPeripheryConfidenceJudgments(1:20));
    
    % Store the values in the array
    peripheryPsyMu20(i) = peripheryCSD20Trials(1);
    peripheryPsySigma20(i) = peripheryCSD20Trials(2);
    peripheryCSDMu20(i) = peripheryCSD20Trials(4);
    peripheryCSDSigma20(i) = peripheryCSD20Trials(5);
    peripheryCSDK20(i) = peripheryCSD20Trials(6);
    
    % Invoke the CSD for 100 trials
    % Returns [mu, sigma, k, finalMu, finalSigma, finalK]
    peripheryCSD100Trials = startCSD(actualPeripheryFixedCoherence, actualPeripheryBinaryChoice, actualPeripheryConfidenceJudgments);
     
    % Store the values in the array
    peripheryPsyMu100(i) = peripheryCSD100Trials(1);
    peripheryPsySigma100(i) = peripheryCSD100Trials(2);
    peripheryCSDMu100(i) = peripheryCSD100Trials(4);
    peripheryCSDSigma100(i) = peripheryCSD100Trials(5);
    peripheryCSDK100(i) = peripheryCSD100Trials(6);
    
end

%close all;

%---------Plot Mu, Sigma, and K----------

% Plot the Mu for the center
figure;
plotMuData(centerPsyMu20, centerPsyMu100, centerCSDMu20, centerCSDMu100);

% Plot the Mu for the periphery
figure;
plotMuData(peripheryPsyMu20, peripheryPsyMu100, peripheryCSDMu20, peripheryCSDMu100);

% Plot the Sigma for the center
figure;
plotSigmaData(centerPsySigma20, centerPsySigma100, centerCSDSigma20, centerCSDSigma100);

% Plot the Sigma for the periphery
figure;
plotSigmaData(peripheryPsySigma20, peripheryPsySigma100, peripheryCSDSigma20, peripheryCSDSigma100);

% Plot the K for the center
figure;
plotKData(centerCSDK20, centerCSDK100);

% Plot the K for the periphery
figure;
plotKData(peripheryCSDK20, peripheryCSDK100);
