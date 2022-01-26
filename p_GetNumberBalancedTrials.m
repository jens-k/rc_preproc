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
%       - stimulation
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

    NumberTrials            = numel(Reasons)/2;

    if mod(NumberTrials, 1) ~= 0
        error('NumberTrials should be integer')
    end

    IdxRejectedOff          = find(~strcmp(Reasons, 'OFF Period'));
    IdxRejectedOther        = find(~strcmp(Reasons, ''));

    IdxBadTrial             = find(ismember(IdxRejectedOff, IdxRejectedOther));
    
    % Subject's information
    TotalTrials(iSubj)      = NumberTrials;
    ValidTrials(iSubj)      = numel(IdxBadTrial);
    
    VerbalOutput{iSubj, 1}  = AllEvents{1, iSubj};
    VerbalOutput{iSubj, 2}  = strcat(string(numel(IdxBadTrial)), '/', ...
        string(NumberTrials));
    VerbalOutput{iSubj, 3}  = round(numel(IdxBadTrial) * 100 / NumberTrials, 1);

end

ToPrint = cell2table(VerbalOutput, ...
    'VariableNames', {'Dataset', 'Rejected/Total', 'Rejected (%)'})
