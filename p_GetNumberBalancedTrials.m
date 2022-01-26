% Script that checks fow many trials would be removed if we consider only
% trials that are part of a complete stimulation cycle [Odor, Vehicle]

% Input
%   - AllEvents (as put out by Andrea) structure with fields
%       [ Field name ]           [ Used ]
%       - sample
%       - offset
%       - description
%       - label
%       - mffkey_cidx
%       - mffkey_gidx
%       - SleepStage
%       - stimulation               Yes
%       - Distance2NextTrigger
%       - Rejected
%       - ReasonForRejection        Yes
%
% Output
%   - TotalTrials   Total number of events per condition
%   - ValidTrials   Number of trials per condition part of a complete cycle
%   - VerbalOutput  Cell:
%                   {Name of dataset, "ValidTrials/TotalTrials", Percentage
%                   of rejected trials}
%
% Parameters
file_AllEvents = 'EventsDescription.mat';


% -------------------------------------------------------------------------

load(file_AllEvents);
                  

TotalTrials     = zeros(size(AllEvents, 2), 1);
ValidTrials     = zeros(size(AllEvents, 2), 1);
VerbalOutput    = cell(size(AllEvents, 2), 3);

for iSubj = 1:size(AllEvents, 2)
    
    SubjectEvents           = AllEvents{2, iSubj};

    Reasons                 = {SubjectEvents.ReasonForRejection};
    Stimulations            = {SubjectEvents.stimulation};

    IdxTrialsOdor           = find(strcmp(Stimulations, 'ODOR'));
    IdxTrialsVehicle        = find(strcmp(Stimulations, 'VEHICLE'));
    
    NumberTrialsOdor        = numel(IdxTrialsOdor);
    NumberTrialsVehicle     = numel(IdxTrialsVehicle);
    
    NumberTrials            = min([NumberTrialsOdor, NumberTrialsVehicle]);
    

    IdxRejectedOff          = find(~strcmp(Reasons, 'OFF Period'));
    IdxRejectedOther        = find(~strcmp(Reasons, ''));

    IdxBadTrial             = find(ismember(IdxRejectedOff, IdxRejectedOther));
    
    % Build complete cycles matrix
    CompleteCycles          = [];
    for iOdor = 1:numel(IdxTrialsOdor)-1
        CompleteCycles(iOdor, :) = IdxTrialsOdor(iOdor):IdxTrialsOdor(iOdor+1)-1;
    end
    
    RejectedCycles          = 0;
    for iCycle = 1:size(CompleteCycles, 1)
        if any(ismember(IdxBadTrial, CompleteCycles(iCycle, :))) % Any
            iSubj
            ismember(IdxBadTrial, CompleteCycles(iCycle, :))
            RejectedCycles = RejectedCycles +1;
        end
    end
    
    % Subject's information
    TotalTrials(iSubj)      = NumberTrials;
    ValidTrials(iSubj)      = RejectedCycles;
    
    VerbalOutput{iSubj, 1}  = AllEvents{1, iSubj};
    VerbalOutput{iSubj, 2}  = strcat(string(numel(IdxBadTrial)), '/', ...
        string(NumberTrials));
    VerbalOutput{iSubj, 3}  = round(numel(IdxBadTrial) * 100 / NumberTrials, 1);

end

ToPrint = cell2table(VerbalOutput, ...
    'VariableNames', {'Dataset', 'Rejected/Total', 'Rejected (%)'})
