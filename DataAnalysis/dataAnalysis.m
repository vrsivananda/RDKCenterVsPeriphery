close all;

% Switch parameters
saveStaircase = 0;

% Add the path to the data folder so that MATLAB can access it
addpath([pwd '/Data']);

% Create a path to the text file with all the subjects
path='RDKCenterVsPeriphery_Subjects_All.txt';
% Make an ID for the subject list file
subjectListFileId=fopen(path);
% Read in the number from the subject list
numberOfSubjects = fscanf(subjectListFileId,'%d');

%-----Prepare arrays to store data-----

% Store for Psy Mu
centerPsyMu20 = [];
peripheryPsyMu20 = [];
centerPsyMu100 = [];
peripheryPsyMu100 = [];

% Store for CSD Mu
centerCSDMu20 = [];
peripheryCSDMu20 = [];
centerCSDMu100 = [];
peripheryCSDMu100 = [];

% Store for Psy Sigma
centerPsySigma20 = [];
peripheryPsySigma20 = [];
centerPsySigma100 = [];
peripheryPsySigma100 = [];

% Store for CSD Mu
centerCSDSigma20 = [];
peripheryCSDSigma20 = [];
centerCSDSigma100 = [];
peripheryCSDSigma100 = [];

% Store for CSD K
centerCSDK20 = [];
peripheryCSDK20 = [];
centerCSDK100 = [];
peripheryCSDK100 = [];

%-----Prepare variables to keep track of discarded data-----

% General counter for discarded subjects
nDiscardedSubjects = 0;

% Discarded because did not get enough practice trials correct
nDiscardedPracticeTrials = 0;
discardedPracticeTrialsSubjectId = {};

% Discarded because incomplete data
nDiscardedIncompleteData = 0;
discardedIncompleteDataSubjectId = {};

% Discarded because curve did not meet criterion
nDiscardedBadCurve = 0;
discardedBadCurveSubjectId = {};

% Counter for valid subjects
nValidSubjects = 0;

%-----Prepare variable to store data to test JS CSD-----
actualCenterFixedCoherenceForJSCSD = [];
actualCenterConfidenceJudgmentForJSCSD = [];

actualPeripheryFixedCoherenceForJSCSD = [];
actualPeripheryConfidenceJudgmentForJSCSD = [];

%----Start looping and get the values----

for i = 1:numberOfSubjects
    
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
    
    % GATEKEEPER #1
    % Only run the rest if the number of correct trials is 8 and above (i.e. above 7)
    if(numberOfCorrectEasyPracticeTrials < 8)
        
        %If less than 8, we increment the counters and save the subjectID
        nDiscardedSubjects = nDiscardedSubjects + 1;
        nDiscardedPracticeTrials = nDiscardedPracticeTrials + 1;
        discardedPracticeTrialsSubjectId{length(discardedPracticeTrialsSubjectId)+1,1} = subjectId;
        
    % Else, we run the analysis
    else
        
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
        
        % GATEKEEPER #2
        % If the data is not complete, then we save it in the discard pile.
        if ( length(actualTrialIndices) ~= 200 || any(isnan(actualCenterCoherence)) || any(isnan(actualPeripheryCoherence)) )
            
            %Increment the counters and save the subjectID
            nDiscardedSubjects = nDiscardedSubjects + 1;
            nDiscardedIncompleteData = nDiscardedIncompleteData + 1;
            discardedIncompleteDataSubjectId{length(discardedIncompleteDataSubjectId)+1,1} = subjectId;
            
        % Else we run the analysis
        else
           
            % ----PLOT----
            
            % Plot a staircase
            figure;
%             plotStaircase(actualCenterCoherence,actualPeripheryCoherence, i, subjectId, saveStaircase);
            
            %---------------------%
            %         CSD         %
            %---------------------%
            
            % ----CENTER----
            
            % Get the sim score for the center and divide by 100 to get range of 0 to 1
            actualCenterConfidenceJudgment = dataStructure.sim_score(actualCenterSimIndices)./100;
            
            % Get the binary form of the sim score
            actualCenterBinaryChoice = (actualCenterConfidenceJudgment > 0.5);
            
            % Get the coherent directions of the actual center trials
            actualCenterCoherentDirection = dataStructure.coherent_direction(actualCenterRDKIndices);
            
            % Fix the coherence array such that leftward direction is negative
            actualCenterFixedCoherence = fixCoherence(actualCenterCoherence, (actualCenterCoherentDirection == 180));
            
            % Invoke the CSD for 20 trials
            % Returns [mu, sigma, k, finalMu, finalSigma, finalK]
            centerCSD20Trials = startCSD(actualCenterFixedCoherence(1:20), actualCenterBinaryChoice(1:20), actualCenterConfidenceJudgment(1:20));

            % Invoke the CSD for 100 trials
            % Returns [mu, sigma, k, finalMu, finalSigma, finalK]
            centerCSD100Trials = startCSD(actualCenterFixedCoherence, actualCenterBinaryChoice, actualCenterConfidenceJudgment);
            
            
            % ----PERIPHERY----
            
            % Get the sim score for the periphery and divide by 100 to get range of 0 to 1
            actualPeripheryConfidenceJudgment = dataStructure.sim_score(actualPeripherySimIndices)./100;
            
            % Get the binary form of the sim score
            actualPeripheryBinaryChoice = (actualPeripheryConfidenceJudgment > 0.5);
            
            % Get the coherent directions of the actual periphery trials
            actualPeripheryCoherentDirection = dataStructure.coherent_direction(actualPeripheryRDKIndices);
            
            % Fix the coherence array such that leftward direction is negative
            actualPeripheryFixedCoherence = fixCoherence(actualPeripheryCoherence, (actualPeripheryCoherentDirection == 180));
            
            % Invoke the CSD for 20 trials
            % Returns [mu, sigma, k, finalMu, finalSigma, finalK]
            peripheryCSD20Trials = startCSD(actualPeripheryFixedCoherence(1:20), actualPeripheryBinaryChoice(1:20), actualPeripheryConfidenceJudgment(1:20));
            
            % Invoke the CSD for 100 trials
            % Returns [mu, sigma, k, finalMu, finalSigma, finalK]
            peripheryCSD100Trials = startCSD(actualPeripheryFixedCoherence, actualPeripheryBinaryChoice, actualPeripheryConfidenceJudgment);
            
            % Checking for obscene K values [delete if unnecessary]
%             if(peripheryCSD20Trials(6) > 10)
%                disp(subjectId);
%                disp(peripheryCSDK20(nValidSubjects));
%             end
            
            % Run the tests on our data to see if we need to discard the it
            discardDataCenter20 = discardDataTest(centerCSD20Trials);
            discardDataCenter100 = discardDataTest(centerCSD100Trials);
            discardDataPeriphery20 = discardDataTest(peripheryCSD20Trials);
            discardDataPeriphery100 = discardDataTest(peripheryCSD100Trials);
            
            % GATEKEEPER #3
            % If the values meet our exclusion criteria, then we discard
            % them
            if(discardDataCenter20 || discardDataCenter100 || discardDataPeriphery20 || discardDataPeriphery100)
%             if(false)    
                %Increment the counters and save the subjectID
                nDiscardedSubjects = nDiscardedSubjects + 1;
                nDiscardedBadCurve = nDiscardedBadCurve + 1;
                discardedBadCurveSubjectId{length(discardedBadCurveSubjectId)+1,1} = subjectId;
                
            % Else we store them in our arrays
            else
            
                % Increment the number of valid subjects counter
                nValidSubjects = nValidSubjects + 1;
                
                %----Sava data for JSCSD----
                
                % Center
                actualCenterFixedCoherenceForJSCSD(nValidSubjects,:) = actualCenterFixedCoherence';
                actualCenterConfidenceJudgmentForJSCSD(nValidSubjects,:) = actualCenterConfidenceJudgment';
                
                % Periphery
                actualPeripheryFixedCoherenceForJSCSD(nValidSubjects,:) = actualPeripheryFixedCoherence';
                actualPeripheryConfidenceJudgmentForJSCSD(nValidSubjects,:) = actualPeripheryConfidenceJudgment';
                
                % ----Center----
                
                % Store the Center 20 values in the array
                centerPsyMu20(nValidSubjects,1) = centerCSD20Trials(1);
                centerPsySigma20(nValidSubjects,1) = centerCSD20Trials(2);
                centerCSDMu20(nValidSubjects,1) = centerCSD20Trials(4);
                centerCSDSigma20(nValidSubjects,1) = centerCSD20Trials(5);
                centerCSDK20(nValidSubjects,1) = centerCSD20Trials(6);
                
                % Store the Center 100 values in the array
                centerPsyMu100(nValidSubjects,1) = centerCSD100Trials(1);
                centerPsySigma100(nValidSubjects,1) = centerCSD100Trials(2);
                centerCSDMu100(nValidSubjects,1) = centerCSD100Trials(4);
                centerCSDSigma100(nValidSubjects,1) = centerCSD100Trials(5);
                centerCSDK100(nValidSubjects,1) = centerCSD100Trials(6);
                
                % ----Periphery----
                
                % Store the Periphery 20 values in the array
                peripheryPsyMu20(nValidSubjects,1) = peripheryCSD20Trials(1);
                peripheryPsySigma20(nValidSubjects,1) = peripheryCSD20Trials(2);
                peripheryCSDMu20(nValidSubjects,1) = peripheryCSD20Trials(4);
                peripheryCSDSigma20(nValidSubjects,1) = peripheryCSD20Trials(5);
                peripheryCSDK20(nValidSubjects,1) = peripheryCSD20Trials(6);
                
                % Store the Periphery 100 values in the array
                peripheryPsyMu100(nValidSubjects,1) = peripheryCSD100Trials(1);
                peripheryPsySigma100(nValidSubjects,1) = peripheryCSD100Trials(2);
                peripheryCSDMu100(nValidSubjects,1) = peripheryCSD100Trials(4);
                peripheryCSDSigma100(nValidSubjects,1) = peripheryCSD100Trials(5);
                peripheryCSDK100(nValidSubjects,1) = peripheryCSD100Trials(6);
            
            end % End of if-else for final exclusion criteria
            
            % Close all for debugging and checking the results one by one
            close all;
            
        end % End of if-else statement that checks if data is complete
    end % End of if-else statement that checks for practice trials
end

close all;

%---------Plot Mu, Sigma, and K in Summary----------

% Plot the Mu for the center
figure;
plotMuSummary(centerPsyMu20, centerPsyMu100, centerCSDMu20, centerCSDMu100);

% Plot the Mu for the periphery
figure;
plotMuSummary(peripheryPsyMu20, peripheryPsyMu100, peripheryCSDMu20, peripheryCSDMu100);

% Plot the Sigma for the center
figure;
plotSigmaSummary(centerPsySigma20, centerPsySigma100, centerCSDSigma20, centerCSDSigma100);

% Plot the Sigma for the periphery
figure;
plotSigmaSummary(peripheryPsySigma20, peripheryPsySigma100, peripheryCSDSigma20, peripheryCSDSigma100);

% Plot the K for the center
figure;
plotKSummary(centerCSDK20, centerCSDK100);

% Plot the K for the periphery
figure;
plotKSummary(peripheryCSDK20, peripheryCSDK100);


% %---------Plot Mu, Sigma, and K Individually----------
%
% % Plot the Mu for the center
% figure;
% plotMuData(centerPsyMu20, centerPsyMu100, centerCSDMu20, centerCSDMu100);
%
% % Plot the Mu for the periphery
% figure;
% plotMuData(peripheryPsyMu20, peripheryPsyMu100, peripheryCSDMu20, peripheryCSDMu100);
%
% % Plot the Sigma for the center
% figure;
% plotSigmaData(centerPsySigma20, centerPsySigma100, centerCSDSigma20, centerCSDSigma100);
%
% % Plot the Sigma for the periphery
% figure;
% plotSigmaData(peripheryPsySigma20, peripheryPsySigma100, peripheryCSDSigma20, peripheryCSDSigma100);
%
% % Plot the K for the center
% figure;
% plotKData(centerCSDK20, centerCSDK100);
%
% % Plot the K for the periphery
% figure;
% plotKData(peripheryCSDK20, peripheryCSDK100);
